module StateMachine
#(
  parameter D = 3,
  parameter TREE_SIZE = 8 * (2**D),
  parameter AES_LATENCY = 29
)
(
  input clk,
  input rst,
  input enable,
  input func, 
  output done,
  output [1:0] state,
  output mB_wr_en,
  output mB_rd_en,
  output [D-1:0] mB_w_addr,
  output [D-1:0] mB_r_addr,
  output mB_r_offset,
  output msg_wr_en,
  output [D-1:0] msg_w_addr
);

enum bit      {EXPAND, HASH} funcs;
enum bit [1:0] {EXP_IDLE, EXP_PRNG, EXP_CAL, EXP_DONE} expand_states;
enum bit [1:0] {HASH_IDLE, HASH_CAL, HASH_DONE} hash_states;

reg [1:0] expand_state, hash_state;

reg [7:0] depth;
reg [31:0] width, index;
// since our AES unit takes 30 cycles to generate result, 
// the write_index will be index + 30 at the beginning of each level. If the write_index < width, 
// it means we have something to write, then mB_wr_en is on.
reg [31:0] write_index;

assign done = (func == EXPAND && expand_state == EXP_DONE) ||
              (func == HASH && hash_state == HASH_DONE)
              ? 1 : 0;

assign state = (func == EXPAND) ? expand_state : hash_state;
// always_comb begin
//   if (func == EXPAND)
//     state = expand_state;
//   else
//     state = hash_state;
// end

assign mB_wr_en = (func == EXPAND && (state == EXP_PRNG || state == EXP_CAL) && (write_index < width)) ? 1 : 0;

// always_comb begin
//   mB_wr_en = 1'b0;
//   if (func == EXPAND) begin
//     if (state == EXP_PRNG || state == EXP_CAL) begin
//       if (write_index < width)
//         mB_wr_en = 1'b1;
//     end
//   end
// end 

assign mB_w_addr = write_index;
assign mB_r_addr = index / 2;
assign mB_r_offset = index % 2;

// always_comb begin
//   mB_w_addr = write_index;
//   mB_r_addr = index / 2;
//   mB_r_offset = index % 2;
// end

assign msg_wr_en = (func == HASH && state == HASH_CAL && (write_index < TREE_SIZE)) ? 1 : 0;
// always_comb begin
//   msg_wr_en = 1'b0;
//   if (func == HASH && state == HASH_CAL) begin
//     if (write_index < TREE_SIZE)
//       mB_wr_en = 1'b1;
//   end
// end 

assign msg_w_addr = write_index;
// always_comb begin
//   msg_w_addr = write_index;
// end



always_ff @(posedge clk, negedge rst) begin
  if (!rst) begin
    expand_state <= EXP_IDLE;
    hash_state <= HASH_IDLE;
    width <= 1;
    depth <= 0;
    index <= 0;
    write_index <= 0 + AES_LATENCY;
  end
  else if (enable) begin
    if (func == EXPAND) begin
      if (expand_state == EXP_IDLE) begin
        width <= 1;
        index <= 0;
        write_index <= 0 + AES_LATENCY;
        expand_state <= EXP_PRNG;
      end
      else if (expand_state == EXP_PRNG) begin
        if (write_index == 0) begin
          depth <= 0;
          index <= 0;
          write_index <= 1 + AES_LATENCY;
          width <= 1;
          expand_state <= EXP_CAL;
        end
        else begin
          write_index <= write_index - 1;
        end
      end
      else if (expand_state == EXP_CAL) begin
        if (depth == D) begin
          expand_state <= EXP_DONE;
        end
        else begin
            if (write_index == 0) begin
              depth <= depth + 1;
              width <= width << 1;
              index <= (width << 1) - 1;
              write_index <= (width << 1) + AES_LATENCY;
            end
            else begin
              if (index > 0) begin
                index <= index - 1;
              end
              write_index <= write_index - 1;
            end
        end
      end
      else begin  //expand_state == EXP_DONE
      end
    end
    else begin // func == HASH
      if (hash_state == HASH_IDLE) begin
        index <= 2**D-1;
        write_index <= 2**D+AES_LATENCY;
        hash_state <= HASH_CAL;
      end
      else if (hash_state == HASH_CAL) begin
        if (write_index == 0) begin
          hash_state <= HASH_DONE;
        end
        else begin
          index <= index - 1;
          write_index <= write_index - 1;
        end
      end
      else if (hash_state == HASH_DONE) begin
      end
    end
  end
end

endmodule
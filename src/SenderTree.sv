module SenderExpand
#(
  parameter D = 3,
  parameter TREE_SIZE = 8 * (2**D),
  parameter AES_LATENCY = 29
)
(
  input clk,
  input rst,
  input start,
  input func,
  input [127:0] seed,
  input [127:0] delta,
//  input [D+2:0] mB_index,
  output done,
  //output [1023:0] out
  output [127:0] out
//  output [127:0] mB_data_out
);

parameter END_D = D + 3;

enum bit      {EXPAND, HASH} funcs;
enum bit [1:0] {EXP_IDLE, EXP_PRNG, EXP_CAL, EXP_DONE} expand_states;
enum bit [1:0] {HASH_IDLE, HASH_CAL, HASH_DONE} hash_states;

wire [127:0] HASH_MASK;
assign HASH_MASK = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFE;

wire [127:0] dm;
assign dm = delta & HASH_MASK;

reg [1:0] expand_state;
reg [1:0] hash_state;

reg [$clog2(D):0] depth;
reg [D:0] width, index;

reg [63:0] prng_counter;

assign done = (func == EXPAND && expand_state == EXP_DONE) ||
              (func == HASH && hash_state == HASH_DONE)
              ? 1 : 0;
assign out = (index % 2 == 0) ? m0_out[127:0] : m1_out[127:0];

//assign mB_data_out = mB_out[127:0];

always_ff @(posedge clk, negedge rst) begin
  if (!rst) begin
    prng_counter <= 0;
    expand_state <= EXP_IDLE;
    hash_state <= HASH_IDLE;
    width <= 1;
    depth <= 0;
    index <= 0;
  end
  else if (start) begin
    if (func == EXPAND) begin
      if (expand_state == EXP_IDLE) begin
        ou_ld <= 1;
        index <= 0;
        expand_state <= EXP_PRNG;
      end
      else if (expand_state == EXP_PRNG) begin
        if (ou_done) begin
          depth <= 0;
          index <= 0;
          width <= 1;
          ou_ld <= 1;
          expand_state <= EXP_CAL;
        end
        else begin
          index <= 0;
          ou_ld <= 0;
        end
      end
      else if (expand_state == EXP_CAL) begin
        if (depth == D) begin
          expand_state <= EXP_DONE;
        end
        else begin
          if (ou_done) begin
            if (index == 0) begin
              depth <= depth + 1;
              width <= width << 1;
              index <= (width << 1) - 1;
              ou_ld <= 1;
            end
            else begin
              index <= index - 1;
              ou_ld <= 1;
            end
          end
          else begin
            ou_ld <= 0;
          end
        end
      end
      else begin  //expand_state == EXP_DONE
      end
    end
    else begin // func == HASH
      if (hash_state == HASH_IDLE) begin
        index <= 0;
        ou_ld <= 1;
        hash_state <= HASH_CAL;
      end
      else if (hash_state == HASH_CAL) begin
        if (ou_done) begin
          ou_ld <= 1;
          if ((index + 1) * 8 >= OT_SIZE) begin
            hash_state <= HASH_DONE;
          end
          else begin
            index <= index + 1;
          end
        end
        else begin
          ou_ld <= 0;
        end
      end
      else if (hash_state == HASH_DONE) begin
      end
    end
  end
end

wire mB_wr_en;
wire [2047:0] mB_in, mB_out;
wire [END_D-1:0] mB_r_addr, mB_w_addr;

// mB_wr_en decider
assign mB_wr_en = (func == EXPAND && ou_done);

// mB write back decider
wire [1023:0] tmp_left_out;
assign tmp_left_out = (func == EXPAND && expand_state == EXP_PRNG) ? left_out ^ left_in : left_out;
assign mB_in[2047:1024] = right_out;
assign mB_in[1023:0]    = tmp_left_out; 

assign mB_r_addr = index / 2;
assign mB_w_addr = index;


// mB ram
BRAM_inst 
#(
  .DATA_WIDTH(2048), 
  .ADDR_WIDTH(END_D)
)
mB
(
  .clk(clk),
  .wr_en(mB_wr_en),
  .data_in(mB_in),
  .data_out(mB_out),
  .read_addr(mB_r_addr),
  .write_addr(mB_w_addr)
);

// tmp_ou_in_1 decider
wire [1023:0] tmp_ou_in_1;
assign tmp_ou_in_1 = (index % 2 == 0) ? mB_out[1023:0] : mB_out[2047:1024];

// // ou_in decider
// wire [1023:0] tmp_ou_in_2;
// assign tmp_ou_in_2[127:0] = tmp_ou_in_1[127:0] & HASH_MASK;
// assign tmp_ou_in_2[255:128] = tmp_ou_in_1[255:128] & HASH_MASK;
// assign tmp_ou_in_2[383:256] = tmp_ou_in_1[383:256] & HASH_MASK;
// assign tmp_ou_in_2[511:384] = tmp_ou_in_1[511:384] & HASH_MASK;
// assign tmp_ou_in_2[639:512] = tmp_ou_in_1[639:512] & HASH_MASK;
// assign tmp_ou_in_2[767:640] = tmp_ou_in_1[767:640] & HASH_MASK;
// assign tmp_ou_in_2[895:768] = tmp_ou_in_1[895:768] & HASH_MASK;
// assign tmp_ou_in_2[1023:896] = tmp_ou_in_1[1023:896] & HASH_MASK;

// wire [1023:0] ou_in;
// assign ou_in = (func == HASH) ? tmp_ou_in_2 : tmp_ou_in_1;


logic ou_ld;
wire ou_done;
assign ou_done = left_done & right_done;

wire [1023:0] left_in, right_in;
wire [1023:0] left_out, right_out;
wire [127:0] left_key, right_key;
wire         left_done, right_done;

// // left_in decider
// wire [1023:0] tmp_left_in;
// assign tmp_left_in[127:0]    = {64'h777BD5E1B71BFDFE, prng_counter + 0};
// assign tmp_left_in[255:128]  = {64'h777BD5E1B71BFDFE, prng_counter + 1};
// assign tmp_left_in[383:256]  = {64'h777BD5E1B71BFDFE, prng_counter + 2};
// assign tmp_left_in[511:384]  = {64'h777BD5E1B71BFDFE, prng_counter + 3};
// assign tmp_left_in[639:512]  = {64'h777BD5E1B71BFDFE, prng_counter + 4};
// assign tmp_left_in[767:640]  = {64'h777BD5E1B71BFDFE, prng_counter + 5};
// assign tmp_left_in[895:768]  = {64'h777BD5E1B71BFDFE, prng_counter + 6};
// assign tmp_left_in[1023:896] = {64'h777BD5E1B71BFDFE, prng_counter + 7};

// assign left_in = (func == EXPAND && expand_state == EXP_PRNG) ? tmp_left_in : ou_in;

// // right_in decider
// wire [1023:0] tmp_right_in;
// assign tmp_right_in[127:0]    = ou_in[127:0] ^ dm;
// assign tmp_right_in[255:128]  = ou_in[255:128] ^ dm;
// assign tmp_right_in[383:256]  = ou_in[383:256] ^ dm;
// assign tmp_right_in[511:384]  = ou_in[511:384] ^ dm;
// assign tmp_right_in[639:512]  = ou_in[639:512] ^ dm;
// assign tmp_right_in[767:640]  = ou_in[767:640] ^ dm;
// assign tmp_right_in[895:768]  = ou_in[895:768] ^ dm;
// assign tmp_right_in[1023:896] = ou_in[1023:896] ^ dm;

// assign right_in = (func == EXPAND) ? ou_in : tmp_right_in;

// left_key decider
// wire [127:0] tmp_left_key;
// assign tmp_left_key = (expand_state == EXP_PRNG) ? seed : 128'd3242342;

// assign left_key = (func == EXPAND) ? tmp_left_key : 128'h0;

// // right_key decider
// assign right_key = (func == EXPAND) ? 128'd8993849 : 128'h0;

OperationUnit left
(
  .clk(clk),
  .rst(rst),
  .ld(ou_ld),
  .in(left_in),
  .key(left_key),
  .done(left_done),
  .out(left_out)
);

OperationUnit right
(
  .clk(clk),
  .rst(rst),
  .ld(ou_ld),
  .in(right_in),
  .key(right_key),
  .done(right_done),
  .out(right_out)
);

wire msg_wr_en;
wire [END_D-1:0] m0_r_addr, m1_r_addr;
wire [END_D-1:0] m0_w_addr, m1_w_addr;
wire [1023:0] m0_in, m1_in;
wire [1023:0] m0_out, m1_out;


assign m0_in = left_out;
assign m1_in = right_out;


// msg_wr_en decider
assign msg_wr_en = (func == HASH && ou_done);

// msg write address
assign m0_w_addr = index;
assign m1_w_addr = index;

BRAM_inst 
#(
  .DATA_WIDTH(1024), 
  .ADDR_WIDTH(END_D)
)
m0
(
  .clk(clk),
  .wr_en(msg_wr_en),
  .data_in(m0_in),
  .data_out(m0_out),
  .read_addr(m0_r_addr),
  .write_addr(m0_w_addr)
);

BRAM_inst 
#(
  .DATA_WIDTH(1024), 
  .ADDR_WIDTH(END_D)
)
m1
(
  .clk(clk),
  .wr_en(msg_wr_en),
  .data_in(m1_in),
  .data_out(m1_out),
  .read_addr(m1_r_addr),
  .write_addr(m1_w_addr)
);

endmodule
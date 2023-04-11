module SenderTreeCluster
#(
  parameter TREE_NUM = 8,
  parameter D = 3,
  parameter AES_LATENCY = 29
)
(
  input clk,
  input rst,
  input enable,
  input func,
  input [127:0] seed,
  input [127:0] delta,
  input [31:0] msg_index,
  output done,
  output reg [127:0] out
);

wire [128*TREE_NUM-1:0] tmp_out;
wire [TREE_NUM-1:0] tmp_done;

assign done = &tmp_done;

genvar i;
generate
  for (i = 0; i < TREE_NUM; i++) begin: TREES
    SenderTreeTop
    #(
      .D(D), 
      .TREE_SIZE(8 * (2**D)),
      .AES_LATENCY(AES_LATENCY),
      .prng_counter(64'h10000000 * i)
    )
    ei
    (
      .clk   (clk),
      .rst   (rst),
      .enable (enable),
      .func  (func),
      .seed  (seed),
      .delta (delta),
      .msg_index(msg_index),
      .done  (tmp_done[i]),
      .out   (tmp_out[128*i-1:128*i])
    );
  end
endgenerate

generate
  for (i = 0; i < TREE_NUM; i++) begin: TREE_SIZE
    always begin
      if (msg_index == i)
        out = tmp_out[128*i+127:128*i];
    end
  end
endgenerate

endmodule
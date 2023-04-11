module OperationUnit
#(
  parameter AES_LATENCY = 29
)
(
  input clk,
  input func,
  input [1:0] state,
  input [1023:0] data_in,
  input [127:0] key,
  output [1023:0] data_out
);

enum bit      {EXPAND, HASH} funcs;
enum bit [1:0] {EXP_IDLE, EXP_PRNG, EXP_CAL, EXP_DONE} expand_states;
enum bit [1:0] {HASH_IDLE, HASH_CAL, HASH_DONE} hash_states;

wire [1023:0] tmp_out;

genvar i;
generate 
  for (i = 0; i < 8; i++) 
  begin: AES_UNITS
    aes_main aes
    (
      .clk     (clk),
      .key     (key),
      .data_in (data_in[128*i+127:128*i]),
      .data_out(tmp_out[128*i+127:128*i])
    );
  end

endgenerate

wire [1023:0] stored_in;

OperationUnitFIFO 
#(
  .AES_LATENCY(AES_LATENCY)
)
fifo
(
  .clk(clk),
  .data_in(data_in),
  .data_out(stored_in)
);

wire is_EXP_PRNG = (func == EXPAND) && (state == EXP_PRNG);

assign data_out = is_EXP_PRNG ? tmp_out : tmp_out ^ stored_in;



endmodule
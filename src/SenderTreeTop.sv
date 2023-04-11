module SenderTreeTop
#(
  parameter D = 3,
  parameter TREE_SIZE = 8 * (2**D),
  parameter AES_LATENCY = 29,
  parameter prng_counter = 0
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

parameter END_D = D + 3;

always_comb begin
  case(msg_index % 16)
    0:  out[127:64] = m1_out[63:0];
    1:  out[127:64] = m1_out[127:64];
    2:  out[127:64] = m1_out[191:128];
    3:  out[127:64] = m1_out[255:192];
    4:  out[127:64] = m1_out[319:256];
    5:  out[127:64] = m1_out[383:320];
    6:  out[127:64] = m1_out[447:384];
    7:  out[127:64] = m1_out[511:448];
    8:  out[127:64] = m1_out[575:512];
    9:  out[127:64] = m1_out[639:576];
    10:  out[127:64] = m1_out[703:640];
    11:  out[127:64] = m1_out[767:704];
    12:  out[127:64] = m1_out[831:768];
    13:  out[127:64] = m1_out[895:832];
    14:  out[127:64] = m1_out[959:896];
    15:  out[127:64] = m1_out[1023:960];
    default:  out[127:64] = 64'b0;
  endcase
  case(msg_index % 16)
    0:  out[63:0] = m0_out[63:0];
    1:  out[63:0] = m0_out[127:64];
    2:  out[63:0] = m0_out[191:128];
    3:  out[63:0] = m0_out[255:192];
    4:  out[63:0] = m0_out[319:256];
    5:  out[63:0] = m0_out[383:320];
    6:  out[63:0] = m0_out[447:384];
    7:  out[63:0] = m0_out[511:448];
    8:  out[63:0] = m0_out[575:512];
    9:  out[63:0] = m0_out[639:576];
    10:  out[63:0] = m0_out[703:640];
    11:  out[63:0] = m0_out[767:704];
    12:  out[63:0] = m0_out[831:768];
    13:  out[63:0] = m0_out[895:832];
    14:  out[63:0] = m0_out[959:896];
    15:  out[63:0] = m0_out[1023:960];
    default:  out[63:0] = 64'b0;
  endcase
end

wire [1:0] state;

StateMachine 
#(
  .D(D),
  .TREE_SIZE(TREE_SIZE),
  .AES_LATENCY(AES_LATENCY)
)
sm
(
  .clk(clk),
  .rst(rst),
  .enable(enable),
  .func(func),
  .done(done),
  .state(state),
  .mB_wr_en(mB_wr_en),
  .mB_w_addr(mB_w_addr),
  .mB_r_addr(mB_r_addr),
  .mB_r_offset(mB_r_offset),
  .msg_wr_en(msg_wr_en),
  .msg_w_addr(msg_w_addr)
);

wire mB_wr_en;
wire [2047:0] mB_in, mB_raw_out;
wire [1023:0] mB_out;
wire [END_D-1:0] mB_r_addr, mB_w_addr;
wire mB_r_offset;

assign mB_in[2047:1024] = right_out;
assign mB_in[1023:0] = left_out;
assign mB_out = mB_r_offset ? mB_raw_out[2047:1024] : mB_raw_out[1023:0];

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
  .data_out(mB_raw_out),
  .read_addr(mB_r_addr),
  .write_addr(mB_w_addr)
);

wire [1023:0] left_in, right_in;
wire [1023:0] left_out, right_out;
wire [127:0] left_key, right_key;


DataPreprocessor
#(
  .prng_counter(prng_counter)
)
dp
(
  .func(func),
  .state(state),
  .data_in(mB_out),
  .delta(delta),
  .left_in(left_in),
  .right_in(right_in)
);

KeyDistributor kd
(
  .func(func),
  .state(state),
  .seed(seed),
  .left_key(left_key),
  .right_key(right_key)
);

OperationUnit 
#(
  .AES_LATENCY(AES_LATENCY)
)
left
(
  .clk(clk),
  .func(func),
  .state(state),
  .data_in(left_in),
  .key(left_key),
  .data_out(left_out)
);

OperationUnit
#(
  .AES_LATENCY(AES_LATENCY)
) 
right
(
  .clk(clk),
  .func(func),
  .state(state),
  .data_in(right_in),
  .key(right_key),
  .data_out(right_out)
);

wire msg_wr_en;
wire [END_D-1:0] msg_w_addr;
wire [END_D-1:0] m0_r_addr, m1_r_addr;
wire [END_D-1:0] m0_w_addr, m1_w_addr;
wire [1023:0] m0_in, m1_in;
wire [1023:0] m0_out, m1_out;

assign m0_w_addr = msg_w_addr;
assign m1_w_addr = msg_w_addr;

assign m0_r_addr = msg_index / 16;
assign m1_r_addr = msg_index / 16;

assign m0_in = left_out;
assign m1_in = right_out;

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
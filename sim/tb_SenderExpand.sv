`timescale 1ns/1ns

module tb_SenderExpand;

logic clk;
logic rst;
logic start;
logic func;
logic [127:0] seed;
logic [127:0] delta;
logic done;
//logic [1023:0] out;
logic [127:0] out;

parameter D = 3;

enum bit {EXPAND, HASH} funcs;

logic [127:0] mB_ram[2**(D-1) * 16];
logic [D-1:0] mB_r_addr, mB_w_addr;
logic mB_wr_en;
logic [127:0] mB_out[8]; 

logic [7:0] depth;
logic [31:0] index; 
logic mB_r_offset;

logic [127:0] left_in[8];
logic [127:0] right_in[8];
logic [127:0] left_out[8];
logic [127:0] right_out[8];
logic [127:0] left_key;
logic [127:0] right_key;

logic [127:0] m0_ram[2**(D-1) * 16];
logic [127:0] m1_ram[2**(D-1) * 16];

logic [31:0] msg_index;

integer clock_cycles;
integer expand_cycles, hash_cycles;

/* wire [127:0] sub_data_out,shift_data_out,mix_data_out; 
assign sub_data_out = ei.left.aes[0].r0.sub_data_out;
assign shift_data_out = ei.left.aes[0].r0.shift_data_out;
assign mix_data_out = ei.left.aes[0].r0.mix_data_out; */

initial begin
  clock_cycles = 0;
  clk = 1;
  rst = 0;
  start = 0;
  func = EXPAND;
  seed = 128'h0;
  delta = 128'h2e2b34ca59fa4c883b2c8aefd44be966;
  msg_index = 32'd0;
  
  #10
  rst = 1;
  start = 1;
  
  #15
  $display("PRNG result [0] = %h", mB_ram[0]);
  $display("PRNG result [1] = %h", mB_ram[1]);
  $display("PRNG result [2] = %h", mB_ram[2]);
  $display("PRNG result [3] = %h", mB_ram[3]);
  $display("PRNG result [4] = %h", mB_ram[4]);
  $display("PRNG result [5] = %h", mB_ram[5]);
  $display("PRNG result [6] = %h", mB_ram[6]);
  $display("PRNG result [7] = %h", mB_ram[7]);
  
  wait (done) begin
    $display("DONE EXPANSION");
    expand_cycles = clock_cycles;
  end
  clock_cycles = 0;
  
  #15
  /* for (int j = 0; j < 2**(D-1); j++) begin
    $display("EXPAND result [%d] = %h", j, ei.mB.ram[j][127:0]);
    $display("EXPAND result [%d] = %h", j, ei.mB.ram[j][255:128]);
    $display("EXPAND result [%d] = %h", j, ei.mB.ram[j][383:256]);
    $display("EXPAND result [%d] = %h", j, ei.mB.ram[j][511:384]);
    $display("EXPAND result [%d] = %h", j, ei.mB.ram[j][639:512]);
    $display("EXPAND result [%d] = %h", j, ei.mB.ram[j][767:640]);
    $display("EXPAND result [%d] = %h", j, ei.mB.ram[j][895:768]);
    $display("EXPAND result [%d] = %h", j, ei.mB.ram[j][1023:896]);
    $display("EXPAND result [%d] = %h", j, ei.mB.ram[j][1151:1024]);
    $display("EXPAND result [%d] = %h", j, ei.mB.ram[j][1279:1152]);
    $display("EXPAND result [%d] = %h", j, ei.mB.ram[j][1407:1280]);
    $display("EXPAND result [%d] = %h", j, ei.mB.ram[j][1535:1408]);
    $display("EXPAND result [%d] = %h", j, ei.mB.ram[j][1663:1536]);
    $display("EXPAND result [%d] = %h", j, ei.mB.ram[j][1791:1664]);
    $display("EXPAND result [%d] = %h", j, ei.mB.ram[j][1919:1792]);
    $display("EXPAND result [%d] = %h", j, ei.mB.ram[j][2047:1920]);
  end */
  
  for (int j = 0; j < 16 * (2**(D-1)); j++) begin
    $display("EXPAND result [%d] = %h", j, mB_ram[j]);
  end
  
  #10
  rst = 0;
  start = 0;
  func = HASH;
  
  #10
  rst = 1;
  start = 1;
  
  wait (done) begin
    $display("DONE HASH");
    hash_cycles = clock_cycles;
  end
  /* for (int j = 0; j < 2**D; j++) begin
    // $display("HASH result [%d] = %h %h", j, m0_ram[j], m1_ram[j]);
    $display("HASH result [%d] = %h %h", j, ei.m0.ram[0][127: 0], ei.m1.ram[0][127: 0]);
    $display("HASH result [%d] = %h %h", j, ei.m0.ram[1][255: 128], ei.m1.ram[1][255: 128]);
    $display("HASH result [%d] = %h %h", j, ei.m0.ram[2][383: 256], ei.m1.ram[2][383: 256]);
    $display("HASH result [%d] = %h %h", j, ei.m0.ram[3][511: 384], ei.m1.ram[3][511: 384]);
    $display("HASH result [%d] = %h %h", j, ei.m0.ram[4][639: 512], ei.m1.ram[4][639: 512]);
    $display("HASH result [%d] = %h %h", j, ei.m0.ram[5][767: 640], ei.m1.ram[5][767: 640]);
    $display("HASH result [%d] = %h %h", j, ei.m0.ram[6][895: 768], ei.m1.ram[6][895: 768]);
    $display("HASH result [%d] = %h %h", j, ei.m0.ram[7][1023: 896], ei.m1.ram[7][1023: 896]);
  end */
  for (int j = 0; j < 8 * (2**D); j++) begin
    $display("HASH result [%d] = %h %h", j, m0_ram[j], m1_ram[j]);
  end
  $display("EXPAND taking %d cycles", expand_cycles);
  $display("HASH taking %d cycles", hash_cycles);
  $finish;
  
end

genvar i;
generate 
  for (i = 0; i < 16*(2**(D-1)); i++) begin: mB_ram_gen
    assign mB_ram[i] = ei.mB.ram[i/16][(i % 16) * 128 + 127:(i % 16) * 128];
    assign m0_ram[i] = ei.m0.ram[i/8][(i % 8) * 128 + 127: (i % 8) * 128];
    assign m1_ram[i] = ei.m1.ram[i/8][(i % 8) * 128 + 127: (i % 8) * 128];
  end
endgenerate

genvar j;
generate 
  for (j = 0; j < 8; j++) begin: test_gen
    assign left_in[j] = ei.left_in[j*128+127:j*128];
    assign right_in[j] = ei.right_in[j*128+127:j*128];
    assign left_out[j] = ei.left_out[j*128+127:j*128];
    assign right_out[j] = ei.right_out[j*128+127:j*128];
    assign mB_out[j]= ei.mB_out[j*128+127:j*128];
  end
endgenerate

assign mB_r_addr = ei.mB_r_addr;
assign mB_w_addr = ei.mB_w_addr;
assign mB_wr_en = ei.mB_wr_en;
assign mB_r_offset = ei.mB_r_offset;

assign left_key = ei.left_key;
assign right_key = ei.right_key;

assign depth = ei.sm.depth;
assign index = ei.sm.index;

always @(clk) begin
  #5 clk <= ~clk;
end

always @(posedge clk) begin
  clock_cycles = clock_cycles + 1;
end

/* SenderTreeCluster
#(
  .TREE_NUM(1),
  .D(D), 
  .AES_LATENCY(29)
)
ei
(
  .clk   (clk),
  .rst   (rst),
  .enable (start),
  .func  (func),
  .seed  (seed),
  .delta (delta),
  .msg_index(msg_index),
  .done  (done),
  .out   (out)
); */

SenderTreeTop
#(
  .D(D), 
  .OT_SIZE(8 * (2**D))
)
ei
(
  .clk   (clk),
  .rst   (rst),
  .enable (start),
  .func  (func),
  .seed  (seed),
  .delta (delta),
  .msg_index(msg_index),
  .done  (done),
  .out   (out)
);

endmodule
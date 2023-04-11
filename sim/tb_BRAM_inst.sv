`timescale 1ns/1ns

module tb_BRAM_inst;

parameter DW = 128;
parameter AW = 3;

logic clk;
logic wr_en;
logic [(DW-1):0] data_in, data_out;
logic [(AW-1):0] read_addr, write_addr;

//reg [(DW-1):0] test_ram[2**AW-1:0] = ram.ram;
//reg [AW-1:0] test_read_addr = ram.read_addr_reg;

initial begin
  clk = 1;
  wr_en = 0;
  for (int i = 0; i < 2**AW; i++) begin
    ram.ram[i] = i;
  end
  
  #10
  for (int i = 0; i < 2**AW; i++) begin
    #10
    read_addr = i;
    $display("read_addr = %d, output = %x", i, ram.ram[i]);
  end
  
  #10
  wr_en = 1;
  for (int i = 0; i < 2**AW; i++) begin
    #10
    write_addr = i;
    data_in = i + 16;
  end
  
  #10
  for (int i = 0; i < 2**AW; i++) begin
    #10
    read_addr = i;
    $display("read_addr = %d, output = %x", i, ram.ram[i]);
  end
  
  
  #20
  $finish;

end

always @(clk) begin
  #5ns clk <= ~clk;
end

  
BRAM_inst
#(
  .DATA_WIDTH(DW),
  .ADDR_WIDTH(AW)
)
ram
(
  .clk(clk),
  .wr_en(wr_en),
  .data_in(data_in),
  .data_out(data_out),
  .read_addr(read_addr),
  .write_addr(write_addr)
);
endmodule

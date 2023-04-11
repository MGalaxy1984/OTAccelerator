//  Xilinx UltraRAM Single Port No Change Mode.  This code implements 
//  a parameterizable UltraRAM block in No Change mode. The behavior of this RAM is 
//  when data is written, the output of RAM is unchanged. Only when write is
//  inactive data corresponding to the address is presented on the output port.
//
module URAM_inst #(
  parameter ADDR_WIDTH = 10,  // Address Width
  parameter DATA_WIDTH = 2048  // Data Width
  // parameter NBPIPE = 3    // Number of pipeline Registers
 ) ( 
    input clk,                    // Clock 
    input rst,                    // Reset
    input wr_en,                     // Write Enable
    input rd_en,
    // input regce,                  // Output Register Enable
    input mem_en,                 // Memory Enable
    input [DATA_WIDTH-1:0] data_in,       // Data Input  
//    input [DWIDTH-1:0] din2,
    input [ADDR_WIDTH-1:0] write_addr,
    input [ADDR_WIDTH-1:0] read_addr,      // Address Input
    input read_r_bit,
    // output reg [DWIDTH-1:0] dout1 
    output [DATA_WIDTH/2-1:0] data_out  // Data Output
   );

(* ram_style = "ultra" *)
reg [DATA_WIDTH-1:0] ram[(1<<ADDR_WIDTH)-1:0];        // Memory Declaration
reg [DATA_WIDTH-1:0] memreg;              
// reg [DWIDTH-1:0] mem_pipe_reg[NBPIPE-1:0];    // Pipelines for memory
/* reg mem_en_pipe_reg[NBPIPE:0];                // Pipelines for memory enable   */

integer          i;

reg stored_bit;

// RAM : Read has one latency, Write has one latency as well.
always @ (posedge clk)
begin
  if (rst) begin
    memreg <= 0;
  end
  if(mem_en) 
  begin
    if(wr_en)
    // begin
      ram[write_addr] <= data_in;
    //   if (write_addr == read_addr)
    //     data_out <= read_r_bit ? data_in[DATA_WIDTH-1:DATA_WIDTH/2] : data_in[DATA_WIDTH/2-1:0];
    //   else
    //     data_out <= read_r_bit ? ram[read_addr][DATA_WIDTH-1:DATA_WIDTH/2] : ram[read_addr][DATA_WIDTH/2-1:0];
    // end
    // else
      memreg <= ram[read_addr];
      stored_bit <= read_r_bit;
  end
end

assign data_out = stored_bit ? memreg[DATA_WIDTH-1:DATA_WIDTH/2] : memreg[DATA_WIDTH/2-1:0];

// always @ (posedge clk)
// begin
//   if (rst)
//     data_out <= 0;
//   else
//     data_out <= memreg;
// end 

endmodule


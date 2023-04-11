module OperationUnitFIFO
#(
  parameter AES_LATENCY = 29
)
(
  input clk,
  input [1023:0] data_in,
  output [1023:0] data_out
);

reg [1023:0] data [0:AES_LATENCY-1];

assign data_out = data[0];

always_ff @(posedge clk) begin
  data[AES_LATENCY-1] <= data_in;
end

genvar i;
generate
  for (i = 0; i < AES_LATENCY - 1; i=i+1) begin: dataflow
    always_ff @(posedge clk) begin
      data[i] <= data[i + 1];
    end
  end
endgenerate


endmodule
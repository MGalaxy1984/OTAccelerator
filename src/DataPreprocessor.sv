module DataPreprocessor 
#(
  parameter prng_counter = 0
)
(
  input func,
  input [1:0] state,
  input [1023:0] data_in,
  input [127:0] delta,
  output [1023:0] left_in,
  output [1023:0] right_in
);

enum bit      {EXPAND, HASH} funcs;
enum bit [1:0] {EXP_IDLE, EXP_PRNG, EXP_CAL, EXP_DONE} expand_states;
enum bit [1:0] {HASH_IDLE, HASH_CAL, HASH_DONE} hash_states;

wire [1023:0] prng_input;
assign prng_input[127:0]    = {64'h777BD5E1B71BFDFE, prng_counter + 64'h0};
assign prng_input[255:128]  = {64'h777BD5E1B71BFDFE, prng_counter + 64'h1};
assign prng_input[383:256]  = {64'h777BD5E1B71BFDFE, prng_counter + 64'h2};
assign prng_input[511:384]  = {64'h777BD5E1B71BFDFE, prng_counter + 64'h3};
assign prng_input[639:512]  = {64'h777BD5E1B71BFDFE, prng_counter + 64'h4};
assign prng_input[767:640]  = {64'h777BD5E1B71BFDFE, prng_counter + 64'h5};
assign prng_input[895:768]  = {64'h777BD5E1B71BFDFE, prng_counter + 64'h6};
assign prng_input[1023:896] = {64'h777BD5E1B71BFDFE, prng_counter + 64'h7};

wire [127:0] HASH_MASK;
assign HASH_MASK = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFE;

wire [1023:0] hash_left;
assign hash_left[127:0] = data_in[127:0] & HASH_MASK;
assign hash_left[255:128] = data_in[255:128] & HASH_MASK;
assign hash_left[383:256] = data_in[383:256] & HASH_MASK;
assign hash_left[511:384] = data_in[511:384] & HASH_MASK;
assign hash_left[639:512] = data_in[639:512] & HASH_MASK;
assign hash_left[767:640] = data_in[767:640] & HASH_MASK;
assign hash_left[895:768] = data_in[895:768] & HASH_MASK;
assign hash_left[1023:896] = data_in[1023:896] & HASH_MASK;

wire [127:0] masked_delta;
assign masked_delta = delta & HASH_MASK;

wire [1023:0] hash_right;
assign hash_right[127:0] = hash_left[127:0] ^ masked_delta;
assign hash_right[255:128] = hash_left[255:128] ^ masked_delta;
assign hash_right[383:256] = hash_left[383:256] ^ masked_delta;
assign hash_right[511:384] = hash_left[511:384] ^ masked_delta;
assign hash_right[639:512] = hash_left[639:512] ^ masked_delta;
assign hash_right[767:640] = hash_left[767:640] ^ masked_delta;
assign hash_right[895:768] = hash_left[895:768] ^ masked_delta;
assign hash_right[1023:896] = hash_left[1023:896] ^ masked_delta;

wire [1023:0] tmp_left_in;
assign tmp_left_in = (func == HASH) ? hash_left : data_in;


assign left_in = (func == EXPAND && state == EXP_PRNG) ? prng_input : tmp_left_in; 
// always_comb begin
//   if (func == EXPAND) begin
//     if (state == EXP_PRNG) begin
//       left_in = prng_input;
//     end
//     else if (state == EXP_CAL) begin
//       left_in = data_in;
//     end
//     else begin
//       left_in = 0;
//     end
//   end
//   else if (func == HASH) begin
//     if (state == HASH_CAL) begin
//       left_in = hash_left;
//     end
//     else begin
//       left_in = 0;
//     end
//   end
//   else begin
//     left_in = 0;
//   end
// end

assign right_in = (func == EXPAND) ? data_in : hash_right; 
// always_comb begin
//   if (func == EXPAND) begin
//     if (state == EXP_PRNG) begin
//       right_in = 0;
//     end
//     else if (state == EXP_CAL) begin
//       right_in = data_in;
//     end
//     else begin
//       right_in = 0;
//     end
//   end
//   else if (func == HASH) begin
//     if (state == HASH_CAL) begin
//       right_in = hash_right;  
//     end
//     else begin
//       right_in = 0;
//     end
//   end
//   else begin
//     right_in = 0;
//   end
// end

endmodule
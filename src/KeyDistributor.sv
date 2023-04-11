module KeyDistributor
(
  input func,
  input [1:0] state,
  input [127:0] seed,
  output [127:0] left_key,
  output [127:0] right_key
);

enum bit      {EXPAND, HASH} funcs;
enum bit [1:0] {EXP_IDLE, EXP_PRNG, EXP_CAL, EXP_DONE} expand_states;
enum bit [1:0] {HASH_IDLE, HASH_CAL, HASH_DONE} hash_states;

assign left_key = (func == EXPAND && state == EXP_CAL) ? 128'd3242342 : seed;
assign right_key = (func == EXPAND && state == EXP_CAL) ? 128'd8993849 : seed;
// always begin
//   if (func == EXPAND) begin
//     if (state == EXP_PRNG) begin
//       left_key = seed;
//     end
//     else if (state == EXP_CAL) begin
//       left_key = 128'd3242342;
//       right_in = 128'd8993849;
//     end
//   end
//   else if (func == HASH) begin
//     if (state == HASH_CAL) begin
//       left_key = seed;
//       right_in = seed;  
//     end
//   end
// end

endmodule
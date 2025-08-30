//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------
module formula_2_pipe
(
    input         clk,
    input         rst,

    input         arg_vld,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,

    output        res_vld,
    output [31:0] res
);
 
//----------------STAGE_1-----------------------------------------------------------    
logic [31:0] cy;
logic        cy_vld;
isqrt #(.n_pipe_stages(8)) inst10_isqrt_c
   (
    .clk(clk),
    .rst(rst),
    .x_vld(arg_vld),
    .x(c),
    .y_vld(cy_vld),
    .y(cy)
   );

   logic [31:0] shifted_b;
   logic shifted_b_vld;

shift_register_with_valid #(.width(32), .depth(8))
inst_shift_register_with_valid_b(
           .clk(clk),
           .rst(rst),

           .in_vld(arg_vld),
           .in_data(b),

           .out_vld(shifted_b_vld),
           .out_data(shifted_b)
    
);

logic [31:0] sum_b_isqrt_c;
logic [31:0] sum_b_isqrt_c_delayed;
logic        c_b_out_vld, c_b_out_vld_delayed;

    assign sum_b_isqrt_c = shifted_b + cy;
    assign c_b_out_vld   = cy_vld & shifted_b_vld;

    always_ff @ (posedge clk)
        if(rst) begin 
            c_b_out_vld_delayed   <= '0;
            sum_b_isqrt_c_delayed <= '0;
        end
        else 
        begin
            sum_b_isqrt_c_delayed <= sum_b_isqrt_c;
            c_b_out_vld_delayed   <= c_b_out_vld;
        end
   //------------------STAGE 2-------------------------------
logic  [31:0] isqrt_sum_b_isqrt_cy;
logic         isqrt_sum_b_isqrt_cy_vld;

isqrt #(.n_pipe_stages(8)) inst_isqrt_sum_b_isqrt_c
(
    .clk(clk),
    .rst(rst),
    .x_vld(c_b_out_vld_delayed),
    .x(sum_b_isqrt_c_delayed),
    .y_vld(isqrt_sum_b_isqrt_cy_vld),
    .y(isqrt_sum_b_isqrt_cy)
);

logic [31:0] shifted_a;
logic [31:0] sum_a_and_isqrt_b_plus_isqrt_c;
logic        shifted_a_vld;

shift_register_with_valid #(.width(32), .depth(17))
inst_shift_register_with_valid_a(
           .clk(clk),
           .rst(rst),

           .in_vld(arg_vld),
           .in_data(a),

           .out_vld(shifted_a_vld),
           .out_data(shifted_a)
    
);

 
logic [31:0] delayed_stage_ii;
logic       c_b_a_out_vld_delayed;
logic       c_b_a_out_vld;

 assign c_b_a_out_vld = shifted_a_vld & isqrt_sum_b_isqrt_cy_vld;
 assign sum_a_and_isqrt_b_plus_isqrt_c = shifted_a + isqrt_sum_b_isqrt_cy;
  
 always_ff @ (posedge clk)
      if(rst) begin
      delayed_stage_ii      <= '0;
      c_b_a_out_vld_delayed <= '0;
  end
  else begin
      delayed_stage_ii      <= sum_a_and_isqrt_b_plus_isqrt_c;
      c_b_a_out_vld_delayed <= c_b_a_out_vld;
  end   

//------------------stage 3-------------------------------------------

isqrt #(.n_pipe_stages(8)) inst_isqrt_sum_a_isqrt_b_plus_isqrt_c
(
    .clk  (clk                  ),
    .rst  (rst                  ),
    .x_vld(c_b_a_out_vld_delayed),
    .x    (delayed_stage_ii     ),
    .y_vld(res_vld              ),
    .y    (res                  )
);



    // Implement a pipelined module formula_2_pipe that computes the result
    // of the formula defined in the file formula_2_fn.svh.
    //  
    // The requirements:
    //
    // 1. The module formula_2_pipe has to be pipelined.
    //
    // It should be able to accept a new set of arguments a, b and c
    // arriving at every clock cycle.
    //
    // It also should be able to produce a new result every clock cycle
    // with a fixed latency after accepting the arguments.
    //
    // 2. Your solution should instantiate exactly 3 instances
    // of a pipelined isqrt module, which computes the integer square root.
    //
    // 3. Your solution should save dynamic power by properly connecting
    // the valid bits.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm


endmodule

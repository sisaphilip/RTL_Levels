// Task  PASS DO NOT CHANGE

module formula_1_pipe
(
    input         clk,
    input         rst,

    input         arg_vld,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,

    output        res_vld,
    output logic [31:0] res
);



   logic          ay_vld;
   logic   [31:0] ay;
   //instance for a
isqrt #(.n_pipe_stages(4)) i_iqrt_a
   (
    .clk(clk),
    .rst(rst),
    .x_vld(arg_vld),
    .x(a),
    .y_vld(ay_vld),
    .y(ay)
   );


   logic          by_vld;
   logic   [31:0] by;
   //instance for a
isqrt #(.n_pipe_stages(4)) i_iqrt_b
   (
    .clk(clk),
    .rst(rst),
    .x_vld(arg_vld),
    .x(b),
    .y_vld(by_vld),
    .y(by)
   );


   logic          cy_vld;
   logic   [31:0] cy;
   //instance for a
isqrt #(.n_pipe_stages(4)) i_iqrt_c
   (
    .clk(clk),
    .rst(rst),
    .x_vld(arg_vld),
    .x(c),
    .y_vld(cy_vld),
    .y(cy)
   );


   logic [31:0] iqrt_sum;

   assign  iqrt_sum = ay + by + cy;

   always_ff @ (posedge clk)
       if(rst)
           res <= '0;
       else if (res_vld)
           res <= iqrt_sum;




   
  // Task:
    // Implement a pipelined module formula_1_pipe that computes result
    // of the formula defined in the file formula_1_fn.svh.
    // The requirements:
    // 
    // 1. The modue formula_1_pipe has to be pipeline.
    // It should be able to accept a new set of arguments a, b and c
    // arriving at every clock cycle.
    // It also should be able to produce a new result every clock cycle
    // with a fixed latency after accepting the arguments.
    // 
    // 2. Your solution should instantiate exactly 3 instances
    // of a pipelined isqrt module,which computes the integer square root
    // 
    // 3. Your solution should save dynamic power by properly connecting
    // the valid bits.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm


endmodule

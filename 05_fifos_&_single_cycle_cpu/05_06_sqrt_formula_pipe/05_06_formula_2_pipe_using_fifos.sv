// Task
module formula_2_pipe_using_fifos
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

//-------------STAGE_1---------------------------------------------------------

logic [31:0] b_fifo_out;


//fifo for b input
flip_flop_fifo_with_counter #(.width(32),.depth(16)) b_fifo(
  .clk(clk), 
  .rst(rst),
  .push(),
  .pop(),
  .write_data(b),
  .read_data(b_fifo_out),
  .empty(),
  .full());

//---------Stage 1 sqrt fn for c-------------------------------------------

logic cy_vld;
logic [31:0] cy;
logic [31:0] stage_i_sum, stage_i_sum_q;

isqrt #(16) i_isqrt_i
(                 
    .clk(clk),
    .rst(rst),
    .x_vld(arg_vld),
    .x(c),
    .y_vld(cy_vld),
    .y(cy)
);
 
 assign stage_i_sum = cy + b_fifo_out;    

 //----------------------stage 1 register--------------------------------------
  
 always_ff @(posedge clk)
   if (rst) 
         stage_i_sum_q     <= '0;
      
       else 
         stage_i_sum_q     <= stage_i_sum;
                  
      

//---------STAGE 2-----------------------------------------------------------

logic [31:0] iiy;
logic iiy_vld;
logic [31:0] stage_ii_sum, stage_ii_sum_q;

//---------stage 2 isqrt ---------------------------------------------------
isqrt #(16) i_isqrt_ii
(
  .clk(clk), 
  .rst(rst),
  .x_vld(arg_vld),
  .x(stage_i_sum_q),
  .y_vld(iiy_vld),
  .y(iiy)
);

logic [31:0] a_fifo_out;

//fifo for a input
flip_flop_fifo_with_counter #(.width(32),.depth(33)) a_fifo(
  .clk(clk), 
  .rst(rst),
  .push(),
  .pop(),
  .write_data(a),
  .read_data(a_fifo_out),
  .empty(),
  .full());

//---------Stage 1 sqrt fn for c-------------------------------------------
assign stage_ii_sum = iiy + a_fifo_out;
 
//---------stage 2 register-------------------------------------------------

 always_ff @(posedge clk)
     if (rst)
         stage_ii_sum_q <= '0;
       else 
         stage_ii_sum_q <= stage_ii_sum;
        
       

//--------STAGE 3 ----------------------------------------------------------

isqrt #(16) i_isqrt_iii
(
  .clk(clk),
  .rst(rst),
  .x_vld(arg_vld),
  .x(stage_ii_sum_q),
  .y_vld(res_vld),
  .y(res)
);

endmodule : formula_2_pipe_using_fifos








    // Task:
    // Implement a pipelined module formula_2_pipe_using_fifos that computes 
    // the result of the formula defined in the file formula_2_fn.svh.
    
    // The requirements:
    // 1. The module formula_2_pipe has to be pipelined.
    // It should be able to accept a new set of arguments a, b and c
    // arriving at every clock cycle.
    // It also should be able to produce a new result every clock cycle
    // with a fixed latency after accepting the arguments.
    // 2. Your solution should instantiate exactly 3 instances
    // of a pipelined isqrt module, which computes the integer square root.
    // 3. Your solution should use FIFOs instead of shift registers
    // which were used in 04_10_formula_2_pipe.sv.
    
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm



// Task
module formula_1_pipe
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
   logic  ay_vld, by_vld, cy_vld;
   logic [15:0] ay,by,cy;

//instance for a
isqrt #(.n_pipe_stages(1)) inst_a
   (
    .clk(clk),.rst(rst),.x_vld(arg_vld),.x(a),.y_vld(ay_vld),.y(ay)
   );

// instance for b
isqrt #(.n_pipe_stages(1)) inst_b          
(               
    .clk(clk),.rst(rst),.x_vld(arg_vld),.x(b),.y_vld(by_vld),.y(by)       
   );   

//instance for c
isqrt #(.n_pipe_stages(1)) inst_c           
(                          
    .clk(clk),.rst(rst),.x_vld(arg_vld),.x(c),.y_vld(cy_vld),.y(cy)       
   );


//combination logic
 logic [31:0]comb_res; 

assign comb_res = {{16{1'b0}},cy + by + ay};
assign res_vld  = ay_vld & by_vld & cy_vld;

//STAGE_REGISTER
always_ff@(posedge clk)
       if(rst)
          res_vld <= 1'b0;
       else if(res_vld)
          res <= comb_res;

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

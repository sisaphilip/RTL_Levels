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

//STAGE A
   logic          ay_vld, by_vld, cy_vld;
   logic   [31:0] ay,by,cy;
   //instance for a
isqrt #(.n_pipe_stages(3)) inst_a
   (
    .clk(clk),
    .rst(rst),
    .x_vld(arg_vld),
    .x(a),
    .y_vld(ay_vld),
    .y(ay)
   );
logic  [31:0] delayed_Aay;
logic         delayed_Aay_vld;

logic  [31:0] delayed_Ab;
logic         delayed_Abarg_vld;

logic  [31:0] delayed_Ac;
logic         delayed_Acarg_vld;


always_ff @ (posedge clk)
begin
    if (rst)              // Reseting datapath stage A
     begin
         delayed_Aay      <= '0;
         delayed_Ab       <= '0;
         delayed_Ac       <= '0;
     end
     else
     begin
         delayed_Aay      <= ay;
         delayed_Aay_vld  <= ay_vld;

         delayed_Ab       <= b;
         delayed_Abarg_vld<= arg_vld;
         
         delayed_Ac       <= c;
         delayed_Acarg_vld<= arg_vld;
     end
 end

//  STAGE B
// instance for b
isqrt #(.n_pipe_stages(3)) inst_b          
(               
    .clk(clk),
    .rst(rst),
    .x_vld(delayed_Abarg_vld),
    .x(delayed_Ab),
    .y_vld(by_vld),
    .y(by)       
   );   

logic  [31:0] delayed_Bay;
logic         delayed_Bay_vld;

logic  [31:0] delayed_Bby;
logic         delayed_Bby_vld;

logic  [31:0] delayed_Bc;
logic         delayed_Bcarg_vld;


always_ff @ (posedge clk)
begin   if (rst)             //resetting datapath for stage B
     begin  
         delayed_Bay       <= '0;
         delayed_Bby       <= '0;
         delayed_Bc        <= '0;
     end
     else
     begin
         delayed_Bay       <= delayed_Aay;
         delayed_Bay_vld   <= delayed_Aay_vld;

         delayed_Bby       <= by ;
         delayed_Bby_vld   <= by_vld;
         
         delayed_Bc        <= delayed_Ac;
         delayed_Bcarg_vld <= delayed_Acarg_vld;
     end
 end
//  STAGE C
//instance for c
isqrt #(.n_pipe_stages(3)) inst_c           
(                          
    .clk(clk),
    .rst(rst),
    .x_vld(delayed_Bcarg_vld),
    .x(delayed_Bc),
    .y_vld(cy_vld),
    .y(cy)       
   );
 

logic  [31:0] delayed_Cay;
logic         delayed_Cay_vld;

logic  [31:0] delayed_Cby;
logic         delayed_Cby_vld;

logic  [31:0] delayed_Ccy;
logic         delayed_Ccy_vld;


always_ff @ (posedge clk)
     if (rst)             //resetting datapath for stage C
     begin  
         delayed_Cay       <= '0;
         delayed_Cby       <= '0;
         delayed_Ccy        <= '0;
     end
     else
     begin
         delayed_Cay       <= delayed_Bay;
         delayed_Cay_vld   <= delayed_Bay_vld;

         delayed_Cby       <= delayed_Bby ;
         delayed_Cby_vld   <= delayed_Bby_vld;
         
         delayed_Ccy        <= cy;
         delayed_Ccy_vld    <= cy_vld;
     end


//assign comb_res = cy + by + ay;
assign res_vld  = delayed_Cay_vld & delayed_Cby_vld & delayed_Ccy_vld;

/*always_ff @ (posedge clk)
  begin 
       if(rst)
          res     <= '0;
       else if(res_vld)
          res     <= delayed_Ccy + delayed_Cby + delayed_Cay;
  end
*/

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

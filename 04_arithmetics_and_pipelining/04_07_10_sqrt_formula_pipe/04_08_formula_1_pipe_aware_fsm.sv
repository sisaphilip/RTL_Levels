// Task
module formula_1_pipe_aware_fsm
(
    input               clk,
    input               rst,

    input               arg_vld,
    input        [31:0] a,
    input        [31:0] b,
    input        [31:0] c,

    output logic        res_vld,
    output logic [31:0] res,

    // isqrt interface

    output logic        isqrt_x_vld,
    output logic [31:0] isqrt_x,

    input               isqrt_y_vld,
    input        [15:0] isqrt_y
);

    enum logic     [2:0 ]
    {
     st_idle       = 3'd0,
     st_wait_a_res = 3'd1,
     st_wait_b_res = 3'd2,
     st_wait_c_res = 3'd3
    }
    state, next_state;

     always_comb
    begin
        next_state  = state;

        isqrt_x_vld = '0;
        isqrt_x     = 'x;  // Don't care

        case (state)
        st_idle:
        begin
            isqrt_x = a;

            if (arg_vld)
            begin
                isqrt_x_vld = '1;
                next_state  = st_wait_a_res;
            end
        end

        st_wait_a_res:
        begin
            isqrt_x = b;

            if (isqrt_y_vld)
            begin
                isqrt_x_vld = '1;
                next_state  = st_wait_b_res;
            end
        end

        st_wait_b_res:
        begin
            isqrt_x = c;

            if (isqrt_y_vld)
            begin
                isqrt_x_vld = '1;
                next_state  = st_wait_c_res;
            end
        end

        st_wait_c_res:
        begin
            if (isqrt_y_vld)
            begin
                next_state = st_idle;
            end
        end
        endcase
    end
 
// Assigning next state
    always_ff @ (posedge clk)
        if (rst)
            state <= st_idle;
        else
            state <= next_state;

// Accumulating the result
    always_ff @ (posedge clk)
        if (rst)
            res_vld <= '0;
        else
            res_vld <= (state == st_wait_c_res & isqrt_y_vld);

    always_ff @ (posedge clk)
        if (state == st_idle)
            res   <= '0;
        else if (isqrt_y_vld)
            res   <= res + isqrt_y;

endmodule










    // Task:
    //
    // Implement a module formula_1_pipe_aware_fsm
    // with a Finite State Machine (FSM)
    // that drives the inputs and consumes the outputs
    // of a single pipelined module isqrt.
    //
    // The formula_1_pipe_aware_fsm module is supposed to be instantiated
    // inside the module formula_1_pipe_aware_fsm_top,
    // together with a single instance of isqrt.
    //
    // The resulting structure has to compute the formula
    // defined in the file formula_1_fn.svh.
    //
    // The formula_1_pipe_aware_fsm module
    // should NOT create any instances of isqrt module,
    // it should only use the input and output ports connecting
    // to the instance of isqrt at higher level of the instance hierarchy.
    //
    // All the datapath computations except the square root calculation,
    // should be implemented inside formula_1_pipe_aware_fsm module.
    // So this module is not a state machine only, it is a combination
    // of an FSM with a datapath for additions and the intermediate data
    // registers.
    //
    // Note that the module formula_1_pipe_aware_fsm NOT pipelined itself.
    // It should be able to accept new arguments a, b and c
    // arriving at every N+3 clock cycles.
    //
    //In order to achieve this latency the FSM is supposed to use the fact
    // that isqrt is a pipelined module.
    //
    // For more details, see the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm




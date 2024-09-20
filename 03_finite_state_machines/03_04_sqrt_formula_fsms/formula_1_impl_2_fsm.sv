// Task
`include "isqrt_fn.svh"

module formula_1_impl_2_fsm
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

    output logic        isqrt_1_x_vld,
    output logic [31:0] isqrt_1_x,

    input               isqrt_1_y_vld,
    input        [15:0] isqrt_1_y,

    output logic        isqrt_2_x_vld,
    output logic [31:0] isqrt_2_x,

    input               isqrt_2_y_vld,
    input        [15:0] isqrt_2_y
);

// module section


isqrt inst1(.x(isqrt_1_y));
isqrt inst2(.x(isqrt_2_y));



enum logic [2:0]
    {
        st_idle       = 3'd0,
        st_wait_a_res = 3'd1,
        st_wait_b_res = 3'd2,
        st_wait_c_res = 3'd3
    }
    state, next_state;

    // Next state and isqrt interface

    always_comb
    begin
        next_state  = state;

        {isqrt_1_x_vld,isqrt_2_x_vld} = {1'b0,1'b0};
        {isqrt_1_x,isqrt_2_x} = {'x,'x};  // Don't care

        case (state)
        st_idle:
        begin
            {isqrt_1_x,isqrt_2_x} = {a,a};
            
            if (arg_vld)
            begin
                {isqrt_1_x_vld,isqrt_2_x_vld} = {1'b1,1'b1};
                next_state  = st_wait_a_res;
            end
        end

        st_wait_a_res:
        begin
            {isqrt_1_x,isqrt_2_x} = {b,b};

            if (isqrt_1_y_vld && isqrt_2_y_vld)
            begin
                {isqrt_1_x_vld,isqrt_2_x_vld} = {1'b1,1'b1};
                next_state  = st_wait_b_res;
            end
        end

        st_wait_b_res:
        begin
            {isqrt_1_x,isqrt_2_x} = {c,c};

            if (isqrt_1_y_vld && isqrt_2_y_vld)
            begin
                {isqrt_1_x_vld,isqrt_2_x_vld} = {1'b1,1'b1};
                 next_state  = st_wait_c_res;
            end
        end

        st_wait_c_res:
        begin
            if (isqrt_1_y_vld && isqrt_2_y_vld )
            begin
                next_state = st_idle;
            end
        end
        endcase
    end
 
// Assigning nex_state to state
    always_ff @ (posedge clk)
        if (rst)
            state <= st_idle;
        else
            state <= next_state;


    always_ff @ (posedge clk)
        if (rst)
      res_vld <= '0;
        else
      res_vld <= (state == st_wait_c_res & (isqrt_1_y_vld && isqrt_2_y_vld));

    always_ff @ (posedge clk)
        if (state == st_idle)
            res <= '0;
        else if (isqrt_1_y_vld && isqrt_2_y_vld)
            res <= res + (isqrt_1_y && isqrt_2_y);

    // Task:
    // Implement a module that calculates the folmula from the `formula_1_fn.svh` file
    // using two instances of the isqrt module in parallel.
    //
    // Design the FSM to calculate an answer and provide the correct `res` value
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm
endmodule

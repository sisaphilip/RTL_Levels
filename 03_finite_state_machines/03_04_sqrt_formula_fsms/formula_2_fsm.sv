// Task
module formula_2_fsm
(
    input                 clk,
    input                 rst,

    input                 arg_vld,
    input          [31:0] a,
    input          [31:0] b,
    input          [31:0] c,
 
    output logic          res_vld,
    output logic   [31:0] res,

    // isqrt interface

    output logic         isqrt_x_vld,
    output logic  [31:0] isqrt_x,

    input                isqrt_y_vld,
    input         [15:0] isqrt_y
);

  

isqrt #(4) _inst_isqrt(
    .clk(clk),
    .rst(rst),
    .x_vld(isqrt_x_vld),
    .x(isqrt_x),
    .y_vld(isqrt_y_vld),
    .y(isqrt_y)


);



    enum logic     [2:0 ]
    {
     st_idle       = 3'd0,
     st_c_res      = 3'd1,
     st_cb_res     = 3'd2,
     st_cba_res    = 3'd3
    }
    state, next_state;

    //------------------------------------------------------------------------
    // Next state and isqrt interface
    logic  [15:0] value_for_c;
    logic  [31:0] value_for_cb;
    logic  [31:0] value_for_cba;

    always_comb
    begin
        next_state  = state;
        isqrt_x_vld = '0;
        isqrt_x     = 'x;  // Don't care

        case (state)
        st_idle:
        begin
            isqrt_x = c;
            
            if (arg_vld)
            begin
                isqrt_x_vld = '1;
                value_for_c = isqrt_y;
                next_state  = st_c_res;
            end
        end

        st_c_res:
        begin
            isqrt_x = b + value_for_c;

            if (isqrt_y_vld)
            begin
                isqrt_x_vld  = '1;
                value_for_cb = isqrt_y;
                next_state   = st_cb_res;
            end
        end

        st_cb_res:
        begin
            isqrt_x = a + value_for_cb;

            if (isqrt_y_vld)
            begin
                isqrt_x_vld   = '1;
                value_for_cba = isqrt_y; 
                next_state    = st_cba_res;
            end
        end

        st_cba_res:
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
            res_vld <= (state == st_cba_res & isqrt_y_vld);

    always_ff @ (posedge clk)
        if (state == st_idle)
            res <= '0;
        else if (isqrt_y_vld)
            res <= res + isqrt_y;

    // Task:
    // Implement a module that calculates the folmula from the `formula_2_fn.svh` file
    // using only one instance of the isqrt module.
    //
    // Design the FSM to calculate answer step-by-step and provide the correct `res` value
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm


endmodule

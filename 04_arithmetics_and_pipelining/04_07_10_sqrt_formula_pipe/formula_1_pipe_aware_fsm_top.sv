//----------------------------------------------------------------------------
// Top file wiring everything together. DO NOT MODIFY
//----------------------------------------------------------------------------

module formula_1_pipe_aware_fsm_top
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

    wire          isqrt_x_vld;
    wire   [31:0] isqrt_x;

    wire          isqrt_y_vld;
    wire   [15:0] isqrt_y;

    formula_1_pipe_aware_fsm i_formula_1_pipe_aware_fsm (
        .clk        (clk),
        .rst        (rst),
        .arg_vld    (arg_vld),
        .a          (a),
        .b          (b),
        .c          (c),
        .res_vld    (res_vld),
        .res        (res),
        
        .isqrt_x_vld(isqrt_x_vld),
        .isqrt_x    (isqrt_x),
        
        .isqrt_y_vld(isqrt_y_vld),
        .isqrt_y    (isqrt_y    )

    );

    isqrt # (.n_pipe_stages (4)) i_isqrt   //4 handles N+3 clock cycles
    (
        .clk   (  clk         ),
        .rst   (  rst         ),
        .x_vld (  isqrt_x_vld ),
        .x     (  isqrt_x     ),
        .y_vld (  isqrt_y_vld ),
        .y     (  isqrt_y     )
    );

endmodule

        /*

        Put any submodules you need here.
    
        You are not allowed to implement your own submodules or functions for the addition,
        subtraction, multiplication, division, comparison or getting the square
        root of floating-point numbers. For such operations you can only use the
        modules from the arithmetic_block_wrappers directory.

        */
module challenge(
        input        clk, rst, arg_vld,
        input        [FLEN - 1:0] a,
        input        [FLEN - 1:0] b,
        input        [FLEN - 1:0] c,

        output logic              res_vld,
        output logic [FLEN - 1:0] res);
    
// Shift register with valid borrowed from 04_09
module shift_register_with_valid # (       
        parameter width = 8, depth = 8)(
        input             clk, rst, in_vld,
        input        [width - 1:0] in_data,
        output                     out_vld,
        output logic [width - 1:0] out_data);

        logic [depth - 1:0] valid;
        logic [width - 1:0] data [0: depth - 1];
        
        always_ff @ (posedge clk)
        if (rst) valid  <= '0;
        else valid      <= {valid[depth-2:0], in_vld};
        
        always_ff @ (posedge clk)
        begin data [0]  <= in_data;
        for (int i = 1; i < depth; i ++)
        data [i]        <= data [i - 1]; end
        

        assign out_vld   = valid [depth - 1];
        assign out_data  = data  [depth - 1];
        endmodule

//----------------------------stage i------------------------------------
        logic [FLEN - 0]  a_square;
        logic [FLEN - 0]a_square_Q;
        logic [FLEN - 0]a_i_delayed;
        f_mult inst_i (
        .clk       (    clk       )
        .rst       (    rst       )
        .a         (    a         )
        .b         (    a         )
        .up_valid  (              )
        .res       (    a_square  )
        .down_valid(              )
        .busy      (              )
        .error     (              ));
        //stage i register
        always_ff @(posedge clk)
        if (rst) a_square_Q      <= '0;
        else begin
        a_square_Q   <= a_square;
        a_i_delayed  <= a; end

//----------------------------stage ii------------------------------------
        logic [FLEN - 0]  a_cubed;
        logic [FLEN - 0]a_cubed_Q;
        logic [FLEN - 0]a_ii_delayed;
        f_mult inst_ii (
        .clk       (    clk        )
        .rst       (    rst        )
        .a         (    a_square_Q )
        .b         (    a_i_delayed)
        .up_valid  (               )
        .res       (    a_cubed    ) 
        .down_valid(               )
        .busy      (               )
        .error     (               ));
        //stage ii register
        always_ff @(posedge clk)
        if (rst) a_cubed_Q <= '0;
        else  begin 
        a_cubed_Q    <= a_cubed;
        a_ii_delayed <= a_i_delayed; end

//----------------------------stage iii------------------------------------
        logic [FLEN - 0]  a_fourth;
        logic [FLEN - 0]a_fourth_Q;
        logic [FLEN - 0]a_iii_delayed;
        f_mult inst_iii (
        .clk       (    clk         )
        .rst       (    rst         )
        .a         (    a_cubed_Q   )
        .b         (    a_ii_delayed)
        .up_valid  (                )
        .res       (    a_fourth    ) 
        .down_valid(                )
        .busy      (                )
        .error     (                ));
        //stage iii register
        always_ff @(posedge clk)
        if (rst) a_fourth_Q <= '0;
        else begin
        a_fourth_Q    <= a_fourth;
        a_iii_delayed <= a_ii_delayed; end

        
//----------------------------stage iv------------------------------------
        logic [FLEN - 0]  a_fifth;
        logic [FLEN - 0]a_fifth_Q;
        
        f_mult inst_iv (
        .clk       (    clk          )
        .rst       (    rst          )
        .a         (    a_fourth_Q   )
        .b         (    a_iii_delayed)
        .up_valid  (                 )
        .res       (    a_fifth      ) 
        .down_valid(                 )
        .busy      (                 )
        .error     (                 ));
        //stage iv register
        always_ff @(posedge clk)
        if (rst) a_fifth_Q <= '0;
        else     a_fifth_Q <= a_fifth;

        logic [FLEN - 0 ]b_delayed, b_shifted;                  // b_values logic
        logic            b_shifted_vld;
        shift_register_with_valid # (.width(FLEN), .depth(3)) inst_b(
        .clk        (  clk           ),
        .rst        (  rst           ),
        .in_vld     (  arg_vld       ),
        .in_data    (  b             ), 
        .out_vld    (  b_shifted_vld ),
        .out_data   (  b_shifted     ));
        
        always_ff @(posedge clk)
        if(rst) b_delayed <= '0;
        else    b_delayed <= b_shifted;

        logic [FLEN - 0 ]b_mult, b_mult_delayed;
        f_mult inst_b_mult (
        .clk       (    clk        )
        .rst       (    rst        )
        .a         (    b_delayed  )
        .b         (    0.3        )
        .up_valid  (               )
        .res       (    b_mult     ) 
        .down_valid(               )
        .busy      (               )
        .error     (               ));
     
        always_ff @(posedge clk)
        if(rst) b_mult_delayed <= '0;
        else    b_mult_delayed <= b_mult;

        logic [FLEN - 0 ]c_delayed, c_shifted;                  // c_values logic
        logic            c_shifted_vld;
        shift_register_with_valid  # (.width(FLEN), .depth(4)) inst_c(
        .clk        (  clk           ),
        .rst        (  rst           ),
        .in_vld     (  arg_vld       ),
        .in_data    (  c             ), 
        .out_vld    (  c_shifted_vld ),
        .out_data   (  c_shifted     ));
        
        always_ff @(posedge clk)
        if(rst) c_delayed <= '0;
        else    c_delayed <= c_shifted;

        //adding 0.3b and a^5
        logic [FLEN - 0] ab_sum, ab_sum_delayed;
        logic            ab_sum_vld;

        f_add inst_ab (
        .clk          (  clk           ),
        .rst          (  rst           ),
        .a            (  a_fifth_Q     ),
        .b            (  b_mult_delayed),
        .up_valid     (                ),
        .res          (  ab_sum        ),
        .down_valid   (                ),
        .busy         (                ),
        .error        (                ));
        
        alway_ff @ (posedge clk)
        if (rst) ab_sum_delayed <= '0;
        else     ab_sum_delayed <= ab_sum;
        
        //adding sum of 0.3b & a^5  with c value
        f_add inst_ab_and_c (
        .clk          (  clk            ),
        .rst          (  rst            ),
        .a            (  ab_sum_delayed ),
        .b            (  c_delayed      ),
        .up_valid     (                 ),
        .res          (  res            ),
        .down_valid   (                 ),
        .busy         (                 ),
        .error        (                 ));
 
        endmodule

        /*
        The Prompt:

        Finish the code of a pipelined block in the file challenge.sv. The block
        computes a formula "a ** 5 + 0.3 * b + c". You are not allowed to
        implement your own submodules or functions for the addition,
        subtraction, multiplication, division, comparison or getting the square
        root of floating-point numbers. For such operations you can only use the
        modules from the arithmetic_block_wrappers directory. You are not
        allowed to change any other files except challenge.sv. You can check the
        results by running the script "simulate". If the script outputs "FAIL"
        or does not output "PASS" from the code in the provided testbench.sv by
        running the provided script "simulate", your design is not working and
        is not an answer to the challenge.

        Your design must be able to accept a new set of the inputs (a, b and c)
        each clock cycle back-to-back and
        generate the computation results without any stalls and without
        requiring empty cycle gaps in the input. The solution code has to be
        synthesizable SystemVerilog RTL.

        A human should not help AI by tipping
        anything on latencies or handshakes of the submodules. The AI has to
        figure this out by itself by analyzing the code in the repository
        directories. Likewise a human should not instruct AI how to build a
        pipeline structure since it makes the exercise meaningless.

        */

        

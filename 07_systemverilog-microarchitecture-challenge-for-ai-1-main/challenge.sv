        /*

        Put any submodules you need here.
    
        You are not allowed to implement your own submodules or functions for the addition,
        subtraction, multiplication, division, comparison or getting the square
        root of floating-point numbers. For such operations you can only use the
        modules from the arithmetic_block_wrappers directory.

        */
//Shift register with valid borrowed from 04_09
module shift_register_with_valid #(       
        parameter width = 8, depth = 8)(
        input                      clk, rst, in_vld,
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


module challenge(
        input                     clk, rst, arg_vld,
        input        [FLEN - 1:0] a,
        input        [FLEN - 1:0] b,
        input        [FLEN - 1:0] c,

        output logic              res_vld,
        output logic [FLEN - 1:0] res);
    
//----------------------------stage_i------------------------------------------------------
        logic [FLEN - 0]   a_square;
        logic [FLEN - 0] a_square_Q;
        logic [FLEN - 0]a_i_Q;
        logic           a_square_vld, a_square_vld_Q, arg_vld_Q;
        f_mult inst_i (
        .clk       (    clk         ),
        .rst       (    rst         ),
        .a         (    a           ),
        .b         (    a           ),
        .up_valid  (    arg_vld     ),
        .res       (    a_square    ),
        .down_valid(    a_square_vld),
        .busy      (                ),
        .error     (                ));
        //stage i register
        always_ff @(posedge clk)
        if (rst) a_square_Q <= '0;
        else begin
        arg_vld_Q       <= arg_vld;
        a_square_vld_Q  <= a_square_vld;
        a_square_Q      <= a_square;
        a_i_Q           <= a; end

//----------------------------stage ii-------------------------------------------------------
        logic [FLEN - 0]  a_cubed;
        logic [FLEN - 0]a_cubed_Q;
        logic [FLEN - 0]a_ii_Q;
        logic           ii_up_valid, a_cubed_vld, a_cubed_vld_Q,a_ii_Q_vld;

        assign ii_up_valid = arg_vld_Q & a_square_vld_Q;
        f_mult inst_ii (
        .clk       (    clk         ),
        .rst       (    rst         ),
        .a         (    a_square_Q  ),
        .b         (    a_i_Q       ),
        .up_valid  (    ii_up_valid ),
        .res       (    a_cubed     ),
        .down_valid(    a_cubed_vld ),
        .busy      (                ),
        .error     (                ));
        //stage ii register
        always_ff @(posedge clk)
        if (rst) a_cubed_Q <= '0;
        else  begin 
        a_ii_Q_vld   <= arg_vld_Q;
        a_cubed_vld_Q<= a_cubed_vld;
        a_cubed_Q    <= a_cubed;
        a_ii_Q       <= a_i_Q; end

//----------------------------stage_iii----------------------------------------------------
        logic [FLEN - 0]  a_fourth;
        logic [FLEN - 0]a_fourth_Q;
        logic [FLEN - 0]a_iii_Q;
        logic           iii_up_valid, a_fourth_vld, a_fourth_vld_Q, a_iii_vld_Q;

        assign iii_up_valid = a_cubed_vld_Q & a_ii_Q_vld;
        f_mult inst_iii (
        .clk       (    clk          ),
        .rst       (    rst          ),
        .a         (    a_cubed_Q    ),
        .b         (    a_ii_Q       ),
        .up_valid  (    iii_up_valid ),
        .res       (    a_fourth     ),
        .down_valid(    a_fourth_vld ),
        .busy      (                 ),
        .error     (                 ));
        //stage iii register
        always_ff @(posedge clk)
        if (rst) a_fourth_Q <= '0;
        else begin
        a_fourth_vld_Q<= a_fourth_vld;
        a_fourth_Q    <= a_fourth;
        a_iii_vld_Q   <= a_ii_Q_vld;
        a_iii_Q       <= a_ii_Q; end

        
//----------------------------stage_iv-----------------------------------------------------
        logic [FLEN - 0]  a_fifth, a_fifth_Q;
        logic             a_fifth_vld, iv_up_valid, a_fifth_vld_Q; 

        assign iv_up_valid = a_iii_vld_Q & a_fourth_vld_Q;
        
        f_mult inst_iv (
        .clk       (    clk          ),
        .rst       (    rst          ),
        .a         (    a_fourth_Q   ),
        .b         (    a_iii_Q      ),
        .up_valid  (    iv_up_valid  ),
        .res       (    a_fifth      ) ,
        .down_valid(    a_fifth_vld  ),
        .busy      (                 ),
        .error     (                 ));
        always_ff @(posedge clk)
        if (rst) 
        a_fifth_Q <= '0;
        else begin a_fifth_Q <= a_fifth;
        a_fifth_vld_Q        <= a_fifth_vld; end


        logic [FLEN - 0 ]b_shifted, b_shifted_Q;                  // b_values logic
        logic            b_shifted_vld, b_shifted_vld_Q;
        shift_register_with_valid #(.width(FLEN), .depth(3)) inst_b(
        .clk        (  clk           ),
        .rst        (  rst           ),
        .in_vld     (  arg_vld       ),
        .in_data    (  b             ), 
        .out_vld    (  b_shifted_vld ),
        .out_data   (  b_shifted     ));
     
        always_ff@(posedge clk)
        if(rst)
        b_shifted_Q <= '0;
        else begin 
        b_shifted_Q     <= b_shifted;
        b_shifted_vld_Q <= b_shifted_vld; end

        logic [FLEN - 0 ]b_mult, b_mult_Q;
        logic            b_mult_vld, b_mult_vld_Q;
        f_mult inst_b_mult (
        .clk       (    clk                 ),
        .rst       (    rst                 ),
        .a         (    b_shifted_Q         ),
        .b         (    0.3                 ),
        .up_valid  (    b_shifted_vld_Q     ),
        .res       (    b_mult              ),
        .down_valid(    b_mult_vld          ),
        .busy      (                        ),
        .error     (                        ));
     
        always_ff @(posedge clk)
        if(rst) b_mult_Q <= '0;
        else  begin
        b_mult_Q    <= b_mult;
        b_mult_vld_Q<= b_mult_vld; end

//------adding 0.3b and  a^5-----------------stage v-------------------------------
        logic [FLEN - 0] ab_sum, ab_sum_Q;
        logic            ab_sum_vld, v_up_valid, v_down_vld, v_down_vld_Q;

        assign v_up_vld = b_mult_vld_Q & a_fifth_vld_Q; 
        
        
        f_add inst_ab (
        .clk          (  clk           ),
        .rst          (  rst           ),
        .a            (  a_fifth_Q     ),
        .b            (  b_mult_Q      ),
        .up_valid     (  v_up_vld      ),
        .res          (  ab_sum        ),
        .down_valid   (  v_down_vld    ),
        .busy         (                ),
        .error        (                ));
        
        always_ff @ (posedge clk)
        if (rst) ab_sum_Q <= '0;
        else   begin   ab_sum_Q <= ab_sum;
        v_down_vld_Q <= v_down_vld; end 

        logic [FLEN - 0 ]c_shifted_Q, c_shifted;                  // c_values logic
        logic            c_shifted_vld, c_shifted_vld_Q;
        shift_register_with_valid  #(.width(FLEN), .depth(5)) inst_c(
        .clk        (  clk            ),
        .rst        (  rst            ),
        .in_vld     (  arg_vld        ),
        .in_data    (  c              ), 
        .out_vld    (  c_shifted_vld  ),
        .out_data   (  c_shifted      ));
        
        always_ff @(posedge clk)
        if(rst) c_shifted_Q <= '0;
        else  begin   c_shifted_Q <= c_shifted;
        c_shifted_vld_Q <= c_shifted_vld; end


//------adding sum of 0.3b & a^5  with c value-------stage vi----------------
        logic  vi_up_vld;
        assign vi_up_vld =  c_shifted_vld_Q & v_down_vld_Q;

        f_add inst_ab_and_c (
        .clk          (  clk            ),
        .rst          (  rst            ),
        .a            (  ab_sum_Q       ),
        .b            (  c_shifted_Q    ),
        .up_valid     (  vi_up_vld      ),
        .res          (  res            ),
        .down_valid   (  res_vld        ),
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

        

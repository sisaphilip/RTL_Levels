/*

Put any submodules you need here.

You are not allowed to implement your own submodules or functions for the addition,
subtraction, multiplication, division, comparison or getting the square
root of floating-point numbers. For such operations you can only use the
modules from the arithmetic_block_wrappers directory.

*/

module flip_flop_fifo_with_counter
# (
    parameter width = 8, depth = 10
)
(
    input                clk,
    input                rst,
    input                push,
    input                pop,
    input  [width - 1:0] write_data,
    output [width - 1:0] read_data,
    output               empty,
    output               full
);

//------------------------------------------------------------------------
// $clog2 for minimum address width that can cover memory size
    localparam pointer_width = $clog2 (depth),    
               counter_width = $clog2 (depth + 1);  
               
    localparam [counter_width - 1:0] max_ptr = counter_width' (depth - 1);

//------------------------------------------------------------------------

    logic [pointer_width - 1:0] wr_ptr, rd_ptr;
    logic [counter_width - 1:0] cnt;

    logic [width - 1:0] data [0: depth - 1];


//------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            wr_ptr <= '0;
        else if (push)
            wr_ptr <= wr_ptr == max_ptr ? '0 : wr_ptr + 1'b1;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            rd_ptr <= '0;
        else if (pop)
            rd_ptr <= rd_ptr == max_ptr ? '0 : rd_ptr + 1'b1;

//------------------------------------------------------------------------

    always_ff @ (posedge clk)
        if (push)
            data [wr_ptr] <= write_data;

    assign read_data = data [rd_ptr];

//------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt <= '0;
        else if (push & ~ pop)
            cnt <= cnt + 1'b1;
        else if (pop & ~ push)
            cnt <= cnt - 1'b1;

//------------------------------------------------------------------------


    assign empty = (cnt == '0);  // Same as "~| cnt"
    assign full = (cnt == depth);

endmodule

module fifo_monitor
# (
    parameter width = 1,
              depth = 0,
              allow_push_when_full_with_pop = 0
)
(
    input               clk,
    input               rst,
    input               push,
    input               pop,
    input [width - 1:0] write_data,
    input [width - 1:0] read_data,
    input               empty,
    input               full
);

    logic [width - 1:0] queue [$];
    logic [width - 1:0] dummy;

    logic was_reset = 0;

    always @ (posedge clk)
    begin
        if (rst)
        begin
            queue = {};
            was_reset = 1;
        end
        else if (was_reset)
        begin
            // Checking

       assert (~ (push & full & ~ (pop & allow_push_when_full_with_pop)));
       assert (~ (pop  & empty));

            assert (~ ( queue.size () == 0     & ~ empty ));
            assert (~ ( queue.size () == depth & ~ full  ));

            // The following assertions
            // will not work with some FIFO microarchitectures.
           // An exam/interview question: what kind of microarchitectures?
            //
            // assert ( empty == ( queue.size () == 0     ));
            // assert ( full  == ( queue.size () == depth ));

            assert (~ (  ~ empty
                       & queue.size () != 0
                       & read_data != queue [0] ));

            // Modeling

            if (push)
                queue.push_back (write_data);

            if (pop & queue.size () > 0)
            begin
                `ifdef __ICARUS__
           // Some version of Icarus has a bug, and this is a workaround
                    queue.delete (0);
                `else
                    dummy = queue.pop_front ();
                `endif
            end

            // Logging

            if (push | pop)
            begin
                if (push)
                    $write ("push %h", write_data);
                else
                    $write ("       ");

                if (pop)
                    $write ("  pop %h", read_data);
                else
                    $write ("        ");

                $write ("  %5s %4s",
                    empty ? "empty" : "     ",
                    full  ? "full"  : "    ");

                $write (" [");

                for (int i = 0; i < queue.size (); i ++)
                    $write (" %h", queue [queue.size () - i - 1]);

                $display (" ]");
            end
        end
    end

endmodule




module challenge(
        input                     clk,
        input                     rst,

        input                     arg_vld,
        output                    arg_rdy,
        input        [FLEN - 1:0] a,
        input        [FLEN - 1:0] b,
        input        [FLEN - 1:0] c,

        output logic              res_vld,
        input  logic              res_rdy,
        output logic [FLEN - 1:0] res);
    
      
//----------------------------stage_i------------------------------------------------------
        logic [FLEN - 0]   a_square;
        logic [FLEN - 0] a_square_Q;
        logic [FLEN - 0]a_i_Q;
        logic           a_square_vld, a_square_vld_Q, arg_vld_Q, NO_mult, arg_rdy_Q, res_rdy_Q;
        assign NO_mult = ~(res_rdy & arg_vld);
        f_mult inst_i (
        .clk       (    clk         ),
        .rst       (    rst         ),
        .a         (    a           ),
        .b         (    a           ),
        .up_valid  (    arg_vld     ),
        .res       (    a_square    ),
        .down_valid(    a_square_vld),
        .busy      (    ~arg_rdy    ),
        .error     (    NO_mult     ));// have an error when ~(res_rdy & arg_vld)
        //stage i register
        always_ff @(posedge clk)
        if (rst) a_square_Q <= '0;
        else begin
        res_rdy_Q       <= res_rdy;
        arg_vld_Q       <= arg_vld;
        arg_rdy_Q       <= arg_rdy;
        a_square_vld_Q  <= a_square_vld;
        a_square_Q      <= a_square;
        a_i_Q           <= a; end

//----------------------------stage ii-------------------------------------------------------
        logic [FLEN - 0]  a_cubed;
        logic [FLEN - 0]a_cubed_Q;
        logic [FLEN - 0]a_ii_Q;
        logic           ii_up_valid, a_cubed_vld, a_cubed_vld_Q,a_ii_Q_vld,ii_rdy, ii_NO_mult;
        logic              = ii_rdy_Q,ii_arg_rdy_Q, ii_res_rdy_Q;
       
        assign ii_rdy      = ~(arg_rdy_Q | res_rdy_Q);
        assign ii_NO_mult  = ~(ii_up_valid & res_rdy_Q);
        assign ii_up_valid = arg_vld_Q & a_square_vld_Q;
       
        f_mult inst_ii (
        .clk       (    clk         ),
        .rst       (    rst         ),
        .a         (    a_square_Q  ),
        .b         (    a_i_Q       ),
        .up_valid  (    ii_up_valid ),
        .res       (    a_cubed     ),
        .down_valid(    a_cubed_vld ),
        .busy      (    ii_rdy      ),    //  ~(res_rdy | arg_rdy)
        .error     (    ii_NO_mult  ));   // ~(res_rdy & arg_vld)
        //stage ii register
        always_ff @(posedge clk)
        if (rst) a_cubed_Q <= '0;
        else  begin
        ii_arg_rdy_Q <= arg_rdy_Q;
        ii_res_rdy_Q <= res_rdy_Q;
        ii_rdy_Q     <= ii_rdy;
        a_ii_Q_vld   <= arg_vld_Q;
        a_cubed_vld_Q<= a_cubed_vld;
        a_cubed_Q    <= a_cubed;
        a_ii_Q       <= a_i_Q; end
//----------------------------stage_iii----------------------------------------------------
        logic [FLEN - 0]  a_fourth;
        logic [FLEN - 0]a_fourth_Q;
        logic [FLEN - 0]a_iii_Q;
        logic           iii_up_valid, a_fourth_vld, a_fourth_vld_Q, a_iii_vld_Q;
        logic           iii_rdy, iii_arg_rdy_Q, iii_res_rdy_Q;

        assign iii_rdy      = ~(ii_arg_rdy_Q | ii_res_rdy_Q )
        assign iii_up_valid = a_cubed_vld_Q & a_ii_Q_vld;
        assign iii_No_mult  = ~(iii_up_valid & iii_res_rdy_Q);

        f_mult inst_iii (
        .clk       (    clk          ),
        .rst       (    rst          ),
        .a         (    a_cubed_Q    ),
        .b         (    a_ii_Q       ),
        .up_valid  (    iii_up_valid ),
        .res       (    a_fourth     ),
        .down_valid(    a_fourth_vld ),
        .busy      (    iii_rdy      ),    //~(arg_rdy | res_rdy)
        .error     (    iii_No_mult  ));   // ~(iii_up_valid & res_rdy)
        //stage iii register
        always_ff @(posedge clk)
        if (rst) a_fourth_Q <= '0;
        else begin
        iii_arg_rdy_Q <= ii_arg_rdy_Q;
        iii_res_rdy_Q <= ii_res_rdy_Q;
        a_fourth_vld_Q<= a_fourth_vld;
        a_fourth_Q    <= a_fourth;
        a_iii_vld_Q   <= a_ii_Q_vld;
        a_iii_Q       <= a_ii_Q; end

        
//----------------------------stage_iv-----------------------------------------------------
        logic [FLEN - 0]  a_fifth, a_fifth_Q;
        logic             a_fifth_vld, iv_up_valid, a_fifth_vld_Q; 
        logic             iv_rdy, iv_res_rdy_Q, iv_arg_rdy_Q;

        assign iv_rdy      = ~(iii_res_rdy_Q | iii_arg_rdy_Q);
        assign iv_up_valid = a_iii_vld_Q & a_fourth_vld_Q;
        assign iv_No_mult  = ~(iv_up_valid & iv_res_rdy_Q); 
        f_mult inst_iv (
        .clk       (    clk          ),
        .rst       (    rst          ),
        .a         (    a_fourth_Q   ),
        .b         (    a_iii_Q      ),
        .up_valid  (    iv_up_valid  ),
        .res       (    a_fifth      ) ,
        .down_valid(    a_fifth_vld  ),
        .busy      (    iv_rdy       ),
        .error     (    iv_No_mult   ));
        always_ff @(posedge clk)
        if (rst) 
        a_fifth_Q <= '0;
        else begin a_fifth_Q <= a_fifth;
        iv_res_rdy_Q         <= iii_res_rdy_Q;
        iv_arg_rdy_Q         <= iii_arg_rdy_Q;
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
        .busy      (    iv_rdy              ),
        .error     (    iv_No_mult          ));
     
        always_ff @(posedge clk)
        if(rst) b_mult_Q <= '0;
        else  begin
        b_mult_Q    <= b_mult;
        b_mult_vld_Q<= b_mult_vld; end

//------adding 0.3b and  a^5-----------------stage v-------------------------------
        logic [FLEN - 0] ab_sum, ab_sum_Q;
        logic            ab_sum_vld, v_up_vld, v_down_vld, v_down_vld_Q;
        logic            v_rdy, v_arg_rdy_Q, v_res_rdy_Q;
       
        assign    v_rdy = ~(iv_arg_rdy_Q | iv_res_rdy_Q);
        assign v_up_vld = b_mult_vld_Q & a_fifth_vld_Q;
        assign v_No_add = ~(v_up_vld & v_res_rdy_Q);
        
        
        f_add inst_ab (
        .clk          (  clk           ),
        .rst          (  rst           ),
        .a            (  a_fifth_Q     ),
        .b            (  b_mult_Q      ),
        .up_valid     (  v_up_vld      ),
        .res          (  ab_sum        ),
        .down_valid   (  v_down_vld    ),
        .busy         (  v_rdy         ),
        .error        (  v_No_add      ));
        
        always_ff @ (posedge clk)
        if (rst) ab_sum_Q <= '0;
        else   begin   ab_sum_Q <= ab_sum;
        v_res_rdy_Q  <= iv_res_rdy_Q;
        v_arg_rdy_Q  <= iv_arg_rdy_Q;
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


//------adding sum of 0.3b & a^5  with (-c) value-------stage vi----------------
        logic  vi_up_vld, vi_res_rdy_Q;

        always_ff @(posedge clk)
        if(rst) vi_res_rdy_Q <= '0;
        else vi_res_rdy_Q    <= v_res_rdy_Q;end
 
        assign  vi_rdy   =  ~(v_res_rdy_Q | v_arg_rdy_Q);
        assign vi_up_vld =  c_shifted_vld_Q & v_down_vld_Q;
        assign vi_No_add = ~(vi_up_vld & vi_res_rdy_Q); 
        f_sub inst_ab_and_c (
        .clk          (  clk            ),
        .rst          (  rst            ),
        .a            (  ab_sum_Q       ),
        .b            (  c_shifted_Q    ),
        .up_valid     (  vi_up_vld      ),
        .res          (  res            ),
        .down_valid   (  res_vld        ),
        .busy         (  vi_rdy         ),
        .error        (                 ));
        
       /*
        The Prompt:
        Finish the code of a pipelined block in the file challenge.sv. The block
        computes a formula "a ** 5 + 0.3 * b - c". Ready/valid handshakes for
        the arguments and the result follow the same rules as ready/valid in AXI
        Stream. When a block is not busy, arg_rdy should be 1, it should not
        wait for arg_vld. You are not allowed to implement your own submodules
        or functions for the addition, subtraction, multiplication, division,
        comparison or getting the square root of floating-point numbers. For
        such operations you can only use the modules from the
        arithmetic_block_wrappers directory. You are not allowed to change any
        other files except challenge.sv. You can check the results by running
        the script "simulate". If the script outputs "FAIL" or does not output
        "PASS" from the code in the provided testbench.sv by running the
        provided script "simulate", your design is not working and is not an
        answer to the challenge. Your design must be able to accept a new set of
        the inputs (a, b and c) each clock cycle back-to-back and generate the
        computation results without any stalls and without requiring empty cycle
        gaps in the input. The solution code has to be synthesizable
        SystemVerilog RTL. A human should not help AI by tipping anything on
        latencies or handshakes of the submodules. The AI has to figure this out
        by itself by analyzing the code in the repository directories. Likewise
        a human should not instruct AI how to build a pipeline structure since
        it makes the exercise meaningless.
        */ 
        endmodule



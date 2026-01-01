        

          module assertions_file(
          input     clk,
          input     rst,
          input     arg_vld,
          input  [63:0] b,c, in_data, b_shifted_Q,c_shifted_Q);

          property challenge_sva;
					@(posedge clk )  disable iff(rst) // add logic to handle reset state
				  $rose(arg_vld) |-> (in_data = b) |-> ##3 (b_shifted_Q == b);
          $rose(arg_vld) |-> (in_data = c) |-> ##5 (c_shifted_Q == c);                                   // non overlapping concurrent assertion
				  endproperty

					challenge_assertions: assert property(challenge_sva)
					                      else $error("Assertion for challenge.sv failed ");
          endmodule

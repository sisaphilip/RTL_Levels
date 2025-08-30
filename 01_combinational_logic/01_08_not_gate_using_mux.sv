module mux
(
  input  d0, d1,
  input  sel,
  output y
);

  assign y = sel ? d1 : d0;

endmodule

//----------------------------------------------------------------------------

module not_gate_using_mux
(
    input  i,
    output o
);

  logic D1_VALUE = '0;
  logic D0_VALUE = '1;
mux mux_inst (.d0(D0_VALUE), .d1(D1_VALUE), .sel(i), .y(o));
    
  // TODO

  // Implement not gate using instance(s) of mux,
  // constants 0 and 1, and wire connections


endmodule

//----------------------------------------------------------------------------

module testbench;

  logic a, o;
  int i;

  not_gate_using_mux inst (a, o);

  initial
    begin
      for (i = 0; i <= 1; i++)
      begin
        assign a = i;

       # 1;

        $display ("TEST ~ %b = %b", a, o);

        if (o !== ~ a)
          begin
            $display ("%s FAIL: %h EXPECTED", `__FILE__, ~ a);
            $finish;
          end
      end    
      $display ("%s          PASS", `__FILE__);
      $finish;
    end
//   not_gate_using_mux inst (a, o);
 

endmodule

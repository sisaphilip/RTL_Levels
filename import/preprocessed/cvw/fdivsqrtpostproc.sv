///////////////////////////////////////////
// fdivsqrtpostproc.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, cturek@hmc.edu
// Modified:13 January 2022
//
// Purpose: Divide/Square root postprocessing
// 
// Documentation: RISC-V System on Chip Design
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module fdivsqrtpostproc (
  input  logic                 clk, reset,
  input  logic                 StallM,
  input  logic [  DIVb+3:0]    WS, WC,            // Q4.DIVb
  input  logic [  DIVb+3:0]    D,                 // Q4.DIVb
  input  logic [  DIVb:0]      FirstU, FirstUM,   // U1.DIVb
  input  logic [  DIVb+1:0]    FirstC,            // Q2.DIVb
  input  logic                 SqrtE,
  input  logic                 SqrtM, SpecialCaseM, 
  input  logic [  XLEN-1:0]    AM,                // U/Q(XLEN.0)
  input  logic                 RemOpM, ALTBM, BZeroM, AsM, BsM, W64M,
  input  logic [  DIVBLEN-1:0] IntNormShiftM,     
  output logic [  DIVb:0]      UmM,               // U1.DIVb result significand
  output logic                 WZeroE,
  output logic                 DivStickyM,
  output logic [  XLEN-1:0]    FIntDivResultM     // U/Q(XLEN.0)
);
  
  logic [  DIVb+3:0]         Sum;
  logic [  INTDIVb+3:0]      W;
  logic [  DIVb:0]           PreUmM;
  logic                      NegStickyM;
  logic                      weq0E, WZeroM;
  logic [  XLEN-1:0]         IntDivResultM;
  logic                      NegQuotM; // Integer quotient is negative

  //////////////////////////
  // Execute Stage: Detect early termination for an exact result
  //////////////////////////

  // check for early termination on an exact result. 
  aplusbeq0 #(  DIVb+4) wspluswceq0(WS, WC, weq0E);

  if (  RADIX == 2) begin: R2EarlyTerm
    logic [  DIVb+3:0] FZeroE, FZeroSqrtE, FZeroDivE;
    logic [  DIVb+2:0] FirstK;
    logic wfeq0E;
    logic [  DIVb+3:0] WCF, WSF;

    assign FirstK = ({1'b1, FirstC} & ~({1'b1, FirstC} << 1));
    assign FZeroSqrtE = {FirstUM[  DIVb], FirstUM, 2'b0} | {FirstK,1'b0};    // F for square root
    assign FZeroDivE =  D << 1;                                    // F for divide
    mux2 #(  DIVb+4) fzeromux(FZeroDivE, FZeroSqrtE, SqrtE, FZeroE);
    csa #(  DIVb+4) fadd(WS, WC, FZeroE, 1'b0, WSF, WCF); // compute {WCF, WSF} = {WS + WC + FZero};
    aplusbeq0 #(  DIVb+4) wcfpluswsfeq0(WCF, WSF, wfeq0E);
    assign WZeroE = weq0E | wfeq0E;
  end else begin
    assign WZeroE = weq0E;
  end 

  //////////////////////////
  // E/M Pipeline register
  //////////////////////////
 
  flopenr #(1) WZeroMReg(clk, reset, ~StallM, WZeroE, WZeroM);

  //////////////////////////
  // Memory Stage: Postprocessing
  //////////////////////////

  //  If the result is not exact, the sticky should be set
  assign DivStickyM = ~WZeroM & ~SpecialCaseM; 

  // Determine if sticky bit is negative 
  assign Sum = WC + WS;
  assign NegStickyM = Sum[  DIVb+3];
  mux2 #(  DIVb+1) preummux(FirstU, FirstUM, NegStickyM, PreUmM); // Select U or U-1 depending on negative sticky bit
  mux2 #(  DIVb+1)    ummux(PreUmM, (PreUmM << 1), SqrtM, UmM);

  // Integer quotient or remainder correction, normalization, and special cases
  if (  IDIV_ON_FPU) begin:intpostproc // Int supported
    logic [  INTDIVb+3:0] UnsignedQuotM, NormRemM, NormRemDM, NormQuotM;
    logic signed [  INTDIVb+3:0] PreResultM, PreResultShiftedM, PreIntResultM;
    logic [  INTDIVb+3:0] DTrunc, SumTrunc;


    assign SumTrunc = Sum[  DIVb+3:  DIVb-  INTDIVb];
    assign DTrunc = D[  DIVb+3:  DIVb-  INTDIVb];

    assign W = $signed(SumTrunc) >>>   LOGR;
    assign UnsignedQuotM = {3'b000, PreUmM[  DIVb:  DIVb-  INTDIVb]};


    // Integer remainder: sticky and sign correction muxes
    assign NegQuotM = AsM ^ BsM; // Integer Quotient is negative
    mux2 #(  INTDIVb+4) normremdmux(W, W+DTrunc, NegStickyM, NormRemDM);


    // Select quotient or remainder and do normalization shift
    mux2 #(  INTDIVb+4)    presresultmux(UnsignedQuotM, NormRemDM, RemOpM, PreResultM);
    assign PreResultShiftedM = PreResultM >> IntNormShiftM;
    mux2 #(  INTDIVb+4)    preintresultmux(PreResultShiftedM, -PreResultShiftedM,AsM ^ (BsM&~RemOpM), PreIntResultM);

    // special case logic
    // terminates immediately when B is Zero (div 0) or |A| has more leading 0s than |B|
    always_comb
      if (BZeroM) begin         // Divide by zero
        if (RemOpM) IntDivResultM = AM;  
        else        IntDivResultM = {(  XLEN){1'b1}};
     end else if (ALTBM) begin // Numerator is small
        if (RemOpM) IntDivResultM = AM;
        else        IntDivResultM = '0;
     end else       IntDivResultM = PreIntResultM[  XLEN-1:0];

    // sign extend result for W64
    if (  XLEN==64) begin
      mux2 #(64) resmux(IntDivResultM[  XLEN-1:0], 
        {{(  XLEN-32){IntDivResultM[31]}}, IntDivResultM[31:0]}, // Sign extending in case of W64
        W64M, FIntDivResultM);
    end else 
      assign FIntDivResultM = IntDivResultM[  XLEN-1:0];
  end else
    assign FIntDivResultM = '0;
endmodule

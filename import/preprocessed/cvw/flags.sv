///////////////////////////////////////////
// flags.sv
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: Post-Processing flag calculation
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

module flags (
  input  logic                 Xs,                     // X sign
  input  logic [  FMTBITS-1:0] OutFmt,                 // output format
  input  logic                 InfIn,                  // is a Inf input being used
  input  logic                 XInf, YInf, ZInf,       // inputs are infinity
  input  logic                 NaNIn,                  // is a NaN input being used
  input  logic                 XSNaN, YSNaN, ZSNaN,    // inputs are signaling NaNs
  input  logic                 XZero, YZero,           // inputs are zero
  input  logic [  NE+1:0]      FullRe,                 // Re with bits to determine sign and overflow
  input  logic [  NE+1:0]      Me,                     // exponent of the normalized sum
  // rounding
  input  logic                 Plus1,                  // do you add one for rounding
  input  logic                 Round, Guard, Sticky,   // bits used to determine rounding
  input  logic                 UfPlus1,                // do you add one for rounding for the unbounded exponent result
  // convert
  input  logic                 CvtOp,                  // conversion operation?
  input  logic                 ToInt,                  // convert to integer
  input  logic                 IntToFp,                // convert integer to floating point
  input  logic                 Int64,                  // convert to 64 bit integer
  input  logic                 Signed,                 // convert to a signed integer
  input  logic [  NE:0]        CvtCe,                  // the calculated expoent - Cvt
  input  logic [1:0]           CvtNegResMsbs,          // the negative integer result's most significant bits
  // divsqrt
  input  logic                 DivOp,                  // conversion operation?
  input  logic                 Sqrt,                   // Sqrt?
  // fma
  input  logic                 FmaOp,                  // Fma operation?
  input  logic                 FmaAs, FmaPs,           // the product and modified Z signs
  // flags
  output logic                 DivByZero,              // divide by zero flag
  output logic                 Overflow,               // overflow flag to select result
  output logic                 Invalid,                // invalid flag to select the result
  output logic                 IntInvalid,             // invalid integer result to select
  output logic [4:0]           PostProcFlg             // flags
);

  logic                        SigNaN;                 // is an input a signaling NaN
  logic                        Inexact;                // final inexact flag
  logic                        FpInexact;              // floating point inexact flag
  logic                        IntInexact;             // integer inexact flag
  logic                        FmaInvalid;             // integer invalid flag
  logic                        DivInvalid;             // integer invalid flag
  logic                        Underflow;              // Underflow flag
  logic                        ResExpGteMax;           // is the result greater than or equal to the maximum floating point expoent
  logic                        ShiftGtIntSz;           // is the shift greater than the the integer size (use Re to account for possible rounding "shift")

  ///////////////////////////////////////////////////////////////////////////////
  // Overflow
  ///////////////////////////////////////////////////////////////////////////////

  // determine if the result exponent is greater than or equal to the maximum exponent or 
  // the shift amount is greater than the integers size (for cvt to int)
  // ShiftGtIntSz calculation:  
  //      a left shift of intlen+1 is still in range but any more than that is an overflow
  //              inital: |      64 0's         |    XLEN     |
  //                      |      64 0's         |    XLEN     | << 64
  //                      |      XLEN           |    00000... |
  //      65 = ...0 0 0 0   0 1 0 0   0 0 0 1
  //          |     or      | |     or      |
  //      33 = ...0 0 0 0   0 0 1 0   0 0 0 1
  //          |     or      | |     or      |
  //      larger or equal if:
  //          - any of the bits after the most significan 1 is one
  //          - the most signifcant in 65 or 33 is still a one in the number and
  //            one of the later bits is one
  if (  FPSIZES == 1) begin
      assign ResExpGteMax = &FullRe[  NE-1:0] | FullRe[  NE];
      assign ShiftGtIntSz = (|FullRe[  NE:7]|(FullRe[6]&~Int64)) | ((|FullRe[4:0]|(FullRe[5]&Int64))&((FullRe[5]&~Int64) | FullRe[6]&Int64));

  end else if (  FPSIZES == 2) begin    
      assign ResExpGteMax = OutFmt ? &FullRe[  NE-1:0] | FullRe[  NE] : &FullRe[  NE1-1:0] | (|FullRe[  NE:  NE1]);

      assign ShiftGtIntSz = (|FullRe[  NE:7]|(FullRe[6]&~Int64)) | ((|FullRe[4:0]|(FullRe[5]&Int64))&((FullRe[5]&~Int64) | FullRe[6]&Int64));
  end else if (  FPSIZES == 3) begin
      always_comb
          case (OutFmt)
                FMT: ResExpGteMax   = &FullRe[  NE-1:0]  | FullRe[  NE];
                FMT1: ResExpGteMax  = &FullRe[  NE1-1:0] | (|FullRe[  NE:  NE1]);
                FMT2: ResExpGteMax  = &FullRe[  NE2-1:0] | (|FullRe[  NE:  NE2]);
              default: ResExpGteMax = 1'bx;
          endcase
          assign ShiftGtIntSz = (|FullRe[  NE:7]|(FullRe[6]&~Int64)) | ((|FullRe[4:0]|(FullRe[5]&Int64))&((FullRe[5]&~Int64) | FullRe[6]&Int64));

  end else if (  FPSIZES == 4) begin        
      always_comb
          case (OutFmt)
                Q_FMT: ResExpGteMax = &FullRe[  Q_NE-1:0] | FullRe[  Q_NE];
                D_FMT: ResExpGteMax = &FullRe[  D_NE-1:0] | (|FullRe[  Q_NE:  D_NE]);
                S_FMT: ResExpGteMax = &FullRe[  S_NE-1:0] | (|FullRe[  Q_NE:  S_NE]);
                H_FMT: ResExpGteMax = &FullRe[  H_NE-1:0] | (|FullRe[  Q_NE:  H_NE]);
          endcase
          assign ShiftGtIntSz = (|FullRe[  Q_NE:7]|(FullRe[6]&~Int64)) | ((|FullRe[4:0]|(FullRe[5]&Int64))&((FullRe[5]&~Int64) | FullRe[6]&Int64));
  end
  
  // calulate overflow flag:
  //                 if the result is greater than or equal to the max exponent(not taking into account sign)
  //                 |           and the exponent isn't negative
  //                 |           |                   if the input isnt infinity or NaN
  //                 |           |                   |            
  assign Overflow = ResExpGteMax & ~FullRe[  NE+1]&~(InfIn|NaNIn|DivByZero);

  ///////////////////////////////////////////////////////////////////////////////
  // Underflow
  ///////////////////////////////////////////////////////////////////////////////

  // calculate underflow flag: detecting tininess after rounding
  //                  the exponent is negative
  //                  |                    the result is subnormal
  //                  |                    |                    the result is normal and rounded from a Subnorm
  //                  |                    |                    |                                      and if given an unbounded exponent the result does not round
  //                  |                    |                    |                                      |                     and if the result is not exact
  //                  |                    |                    |                                      |                     |               and if the input isnt infinity or NaN
  //                  |                    |                    |                                      |                     |               |
  assign Underflow = ((FullRe[  NE+1] | (FullRe == 0) | ((FullRe == 1) & (Me == 0) & ~(UfPlus1&Guard)))&(Round|Sticky|Guard))&~(InfIn|NaNIn|DivByZero|Invalid);

  ///////////////////////////////////////////////////////////////////////////////
  // Inexact
  ///////////////////////////////////////////////////////////////////////////////

  // Set Inexact flag if the result is diffrent from what would be outputed given infinite precision
  //      - Don't set the underflow flag if an underflowed res isn't outputed
  assign FpInexact = (Sticky|Guard|Overflow|Round)&~(InfIn|NaNIn|DivByZero|Invalid);
  
  //                  if the res is too small to be represented and not 0
  //                  |                                     and if the res is not invalid (outside the integer bounds)
  //                  |                                     |
  assign IntInexact = ((CvtCe[  NE]&~XZero)|Sticky|Round|Guard)&~IntInvalid;

  // select the inexact flag to output
  assign Inexact = ToInt ? IntInexact : FpInexact;

  ///////////////////////////////////////////////////////////////////////////////
  // Invalid
  ///////////////////////////////////////////////////////////////////////////////

  // Set Invalid flag for following cases:
  //   1) any input is a signaling NaN
  //   2) Inf - Inf (unless x or y is NaN)
  //   3) 0 * Inf

  // invalid flag for integer result
  //                  if the input is NaN or infinity
  //                  |           if the integer res overflows (out of range) 
  //                  |           |                                  if the input was negative but ouputing to a unsigned number
  //                  |           |                                  |                    the res doesn't round to zero
  //                  |           |                                  |                    |               or the res rounds up out of bounds
  //                  |           |                                  |                    |                       and the res didn't underflow
  //                  |           |                                  |                    |                       |
  assign IntInvalid = NaNIn|InfIn|(ShiftGtIntSz&~FullRe[  NE+1])|((Xs&~Signed)&(~((CvtCe[  NE]|(~|CvtCe))&~Plus1)))|(CvtNegResMsbs[1]^CvtNegResMsbs[0]);
  //                                                                                                     |
  //                                                                                                     or when the positive res rounds up out of range
  
  assign SigNaN = (XSNaN&~(IntToFp&CvtOp)) | (YSNaN&~CvtOp) | (ZSNaN&FmaOp);
  
  // invalid flag for fma
  assign FmaInvalid = ((XInf | YInf) & ZInf & (FmaPs ^ FmaAs) & ~NaNIn) | (XZero & YInf) | (YZero & XInf);
  
  //invalid flag for division
  assign DivInvalid = ((XInf & YInf) | (XZero & YZero))&~Sqrt | (Xs&Sqrt&~NaNIn&~XZero);

  assign Invalid = SigNaN | (FmaInvalid&FmaOp) | (DivInvalid&DivOp);

  ///////////////////////////////////////////////////////////////////////////////
  // Divide by Zero
  ///////////////////////////////////////////////////////////////////////////////

  // if dividing by zero and not 0/0
  //  - don't set flag if an input is NaN or Inf(IEEE says has to be a finite numerator)
  assign DivByZero = YZero&DivOp&~Sqrt&~(XZero|NaNIn|InfIn);  

  ///////////////////////////////////////////////////////////////////////////////
  // final flags
  ///////////////////////////////////////////////////////////////////////////////

  // Combine flags
  //      - to integer results do not set the underflow or overflow flags
  assign PostProcFlg = {Invalid|(IntInvalid&CvtOp&ToInt), DivByZero, Overflow&~(ToInt&CvtOp), Underflow&~(ToInt&CvtOp), Inexact};

endmodule

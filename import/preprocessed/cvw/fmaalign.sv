///////////////////////////////////////////
// fmaalign.sv
//
// Written:  6/23/2021 me@KatherineParry.com, David_Harris@hmc.edu
// Modified: 
//
// Purpose: FMA alginment shift
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

module fmaalign (
  input  logic [  NE-1:0]      Xe, Ye, Ze,          // biased exponents in B(NE.0) format
  input  logic [  NF:0]        Zm,                  // significand in U(0.NF) format]
  input  logic                 XZero, YZero, ZZero, // is the input zero
  output logic [  FMALEN-1:0]  Am,                  // addend aligned for addition in U(NF+5.2NF+1)
  output logic                 ASticky,             // Sticky bit calculated from the aliged addend
  output logic                 KillProd             // should the product be set to zero
);

  logic [  NE+1:0]             ACnt;                // how far to shift the addend to align with the product in Q(NE+2.0) format
  logic [  FMALEN+  NF-1:0]    ZmShifted;           // output of the alignment shifter including sticky bits U(NF+5.3NF+1)
  logic [  FMALEN+  NF-1:0]    ZmPreshifted;        // input to the alignment shifter U(NF+5.3NF+1)
  logic                        KillZ;               // should the addend be killed

  ///////////////////////////////////////////////////////////////////////////////
  // Alignment shifter
  ///////////////////////////////////////////////////////////////////////////////

  // determine the shift count for alignment
  //      - negative means Z is larger, so shift Z left
  //      - positive means the product is larger, so shift Z right
  // This could have been done using Pe, but ACnt is on the critical path so we replicate logic for speed
  assign ACnt = {2'b0, Xe} + {2'b0, Ye} - {2'b0, (  NE)'(  BIAS)} + (  NE+2)'(  NF+3) - {2'b0, Ze};

  // Default Addition with only inital left shift
  // extra bit at end and beginning so the correct guard bit is calculated when subtracting
  //  |   54'b0    |  106'b(product)  | 2'b0 |
  //  | addnend    |

  assign ZmPreshifted = {Zm,(  FMALEN-1)'(0)};
  assign KillProd     = (ACnt[  NE+1]&~ZZero)|XZero|YZero;
  assign KillZ        = $signed(ACnt)>$signed((  NE+2)'(3)*(  NE+2)'(  NF)+(  NE+2)'(5));

  always_comb begin
    // If the product is too small to effect the sum, kill the product
    //  |   54'b0    |  106'b(product)  | 2'b0 |
    //  | addnend    |
    if (KillProd) begin
        ZmShifted = {(  NF+3)'(0), Zm, (2*  NF+2)'(0)};
        ASticky   = ~(XZero|YZero);

    // If the addend is too small to effect the addition        
    //      - The addend has to shift two past the end of the product to be considered too small
    //      - The 2 extra bits are needed for rounding
      
    //  |   54'b0    |  106'b(product)  | 2'b0 |
    //  | addnend    |
    end else if (KillZ)  begin
        ZmShifted = '0;
        ASticky   = ~ZZero;

    // If the Addend is shifted right
    //  |   54'b0    |  106'b(product)  | 2'b0 |
    //  | addnend    |
    end else begin
        ZmShifted = ZmPreshifted >> ACnt;
        ASticky   = |(ZmShifted[  NF-1:0]); 
    end
  end

  assign Am = ZmShifted[  FMALEN+  NF-1:  NF];

endmodule

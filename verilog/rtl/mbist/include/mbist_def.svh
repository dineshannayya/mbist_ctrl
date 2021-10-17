///////////////////////////////////////////////////////////////////////
// SPDX-FileCopyrightText: 2021 , Dinesh Annayya                          
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0
// SPDX-FileContributor: Created by Dinesh Annayya <dinesha@opencores.org>
//
//////////////////////////////////////////////////////////////////////
`ifndef BIST_DEFINE_SVH
`define BIST_DEFINE_SVH

// BIST ADDRESS CONTRL
//
parameter BIST_ADDR_WD    = 10     ;
parameter BIST_ADDR_START = 10'h000 ; 
parameter BIST_ADDR_END   = 10'h3FB ;

// BIST DATA CONTRL
parameter BIST_DATA_WD        = 32;
parameter BIST_DATA_PAT_SIZE  = 8;
parameter BIST_DATA_PAT_TYPE1 = 64'h5555_5555_5555_5555;
parameter BIST_DATA_PAT_TYPE2 = 64'h3333_3333_3333_3333;
parameter BIST_DATA_PAT_TYPE3 = 64'h0F0F_0F0F_0F0F_0F0F;
parameter BIST_DATA_PAT_TYPE4 = 64'h00FF_00FF_00FF_00FF;
parameter BIST_DATA_PAT_TYPE5 = 64'h0000_FFFF_0000_FFFF;
parameter BIST_DATA_PAT_TYPE6 = 64'h0000_0000_FFFF_FFFF;
parameter BIST_DATA_PAT_TYPE7 = 64'hFFFF_FFFF_FFFF_FFFF;
parameter BIST_DATA_PAT_TYPE8 = 64'h0000_0000_0000_0000;

// BIST STIMULATION SELECT

parameter  BIST_STI_SIZE = 5;
parameter  BIST_STI_WD   = 12;
parameter  BIST_STIMULUS_TYPE1 = 12'b100100100100;
parameter  BIST_STIMULUS_TYPE2 = 12'b100010101011;
parameter  BIST_STIMULUS_TYPE3 = 12'b110011100010;
parameter  BIST_STIMULUS_TYPE4 = 12'b000010101011;
parameter  BIST_STIMULUS_TYPE5 = 12'b010011100010;
parameter  BIST_STIMULUS_TYPE6 = 12'b000000000000;
parameter  BIST_STIMULUS_TYPE7 = 12'b000000000000;
parameter  BIST_STIMULUS_TYPE8 = 12'b000000000000;


// Operation 
parameter  BIST_OP_SIZE        = 3;

// BIST ADDRESS REPAIR
parameter  BIST_RAD_WD_I            = BIST_ADDR_WD;
parameter  BIST_RAD_WD_O            = BIST_ADDR_WD;
parameter  BIST_ERR_LIMIT           = 4;
// Make Sure that this address in outside the valid address range
parameter  BIST_REPAIR_ADDR_START   = 10'h3FC ; 

`endif // BIST_DEFINE_SVH
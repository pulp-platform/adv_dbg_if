//////////////////////////////////////////////////////////////////////
////                                                              ////
////  adbg_top.v                                                  ////
////                                                              ////
////                                                              ////
////  This file is part of the SoC Advanced Debug Interface.      ////
////                                                              ////
////  Author(s):                                                  ////
////       Nathan Yawn (nathan.yawn@opencores.org)                ////
////                                                              ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2008-2010 Authors                              ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////


// Top module
module adbg_top  
    #(
        parameter NB_CORES       = 4,
        parameter AXI_ADDR_WIDTH = 32,
        parameter AXI_DATA_WIDTH = 64,
        parameter AXI_USER_WIDTH = 6,
        parameter AXI_ID_WIDTH   = 3
    ) (
        // JTAG signals
        input  logic           tck_i,
        input  logic           tdi_i,
        output logic           tdo_o,
        input  logic           rst_i,


        // TAP states
        input  logic                   shift_dr_i,
        input  logic                   pause_dr_i,
        input  logic                   update_dr_i,
        input  logic                   capture_dr_i,

        // Instructions
        input  logic                       debug_select_i,

        // CPU signals
        input  logic [NB_CORES-1:0]        cpu_clk_i,
        output logic [NB_CORES-1:0] [31:0] cpu_addr_o, 
        input  logic [NB_CORES-1:0] [31:0] cpu_data_i, 
        output logic [NB_CORES-1:0] [31:0] cpu_data_o,
        input  logic [NB_CORES-1:0]        cpu_bp_i,
        output logic [NB_CORES-1:0]        cpu_stall_o,
        output logic [NB_CORES-1:0]        cpu_stb_o,
        output logic [NB_CORES-1:0]        cpu_we_o,
        input  logic [NB_CORES-1:0]        cpu_ack_i,
        output logic [NB_CORES-1:0]        cpu_rst_o,
		
		// AXI4 MASTER
		//***************************************
		input  logic                        axi_aclk,
		input  logic                        axi_aresetn,
		// WRITE ADDRESS CHANNEL
		output logic                        axi_master_aw_valid,
		output logic [AXI_ADDR_WIDTH-1:0]   axi_master_aw_addr,
		output logic [2:0]                  axi_master_aw_prot,
		output logic [3:0]                  axi_master_aw_region,
		output logic [7:0]                  axi_master_aw_len,
		output logic [2:0]                  axi_master_aw_size,
		output logic [1:0]                  axi_master_aw_burst,
		output logic                        axi_master_aw_lock,
		output logic [3:0]                  axi_master_aw_cache,
		output logic [3:0]                  axi_master_aw_qos,
		output logic [AXI_ID_WIDTH-1:0]     axi_master_aw_id,
		output logic [AXI_USER_WIDTH-1:0]   axi_master_aw_user,
		input  logic                        axi_master_aw_ready,
    
		// READ ADDRESS CHANNEL
		output logic                        axi_master_ar_valid,
		output logic [AXI_ADDR_WIDTH-1:0]   axi_master_ar_addr,
		output logic [2:0]                  axi_master_ar_prot,
		output logic [3:0]                  axi_master_ar_region,
		output logic [7:0]                  axi_master_ar_len,
		output logic [2:0]                  axi_master_ar_size,
		output logic [1:0]                  axi_master_ar_burst,
		output logic                        axi_master_ar_lock,
		output logic [3:0]                  axi_master_ar_cache,
		output logic [3:0]                  axi_master_ar_qos,
		output logic [AXI_ID_WIDTH-1:0]     axi_master_ar_id,
		output logic [AXI_USER_WIDTH-1:0]   axi_master_ar_user,
		input  logic                        axi_master_ar_ready,
    
		// WRITE DATA CHANNEL
		output logic                        axi_master_w_valid,
		output logic [AXI_DATA_WIDTH-1:0]   axi_master_w_data,
		output logic [AXI_DATA_WIDTH/8-1:0] axi_master_w_strb,
		output logic [AXI_USER_WIDTH-1:0]   axi_master_w_user,
		output logic                        axi_master_w_last,
		input  logic                        axi_master_w_ready,
    
		// READ DATA CHANNEL
		input  logic                        axi_master_r_valid,
		input  logic [AXI_DATA_WIDTH-1:0]   axi_master_r_data,
		input  logic [1:0]                  axi_master_r_resp,
		input  logic                        axi_master_r_last,
		input  logic [AXI_ID_WIDTH-1:0]     axi_master_r_id,
		input  logic [AXI_USER_WIDTH-1:0]   axi_master_r_user,
		output logic                        axi_master_r_ready,
                                            
		// WRITE RESPONSE CHANNEL           
		input  logic                        axi_master_b_valid,
		input  logic [1:0]                  axi_master_b_resp,
		input  logic [AXI_ID_WIDTH-1:0]     axi_master_b_id,
		input  logic [AXI_USER_WIDTH-1:0]   axi_master_b_user,
		output logic                        axi_master_b_ready
    );


   wire 	 tdo_axi;
   wire 	 [NB_CORES-1:0] tdo_cpu;

   // Registers
   reg [52:0] input_shift_reg;  // 1 bit sel/cmd, 4 bit opcode, 32 bit address, 16 bit length = 53 bits
   reg  [4:0] module_id_reg;   // Module selection register


   // Control signals
   wire               select_cmd;      // True when the command (registered at Update_DR) is for top level/module selection
   wire         [4:0] module_id_in;    // The part of the input_shift_register to be used as the module select data
   reg  [NB_CORES:0] module_selects;  // Select signals for the individual modules, number of modules = NB_CORES+1
   wire               select_inhibit;  // OR of inhibit signals from sub-modules, prevents latching of a new module ID
   wire [NB_CORES:0] module_inhibit;  // signals to allow submodules to prevent top level from latching new module ID

    integer i;

   ///////////////////////////////////////
   // Combinatorial assignments

    assign select_cmd   = input_shift_reg[52];
    assign module_id_in = input_shift_reg[51:47];

//////////////////////////////////////////////////////////
// Module select register and select signals
//////////////////////////////////////////////////////////

    always @ (posedge tck_i or posedge rst_i)
    begin
        if (rst_i)
            module_id_reg <= 5'h0;
        else if(debug_select_i && select_cmd && update_dr_i && !select_inhibit)       // Chain select
            module_id_reg <= module_id_in;
    end

    always_comb
    begin 
        module_selects = 'h0;
    	for(i=0; i<=NB_CORES; i++)
    	begin 
    		if ( module_id_reg == i )
    			module_selects[i] = 1'b1;
    		else
    			module_selects[i] = 1'b0;
    	end
    end
//////////////////////////////////////////////////////////


///////////////////////////////////////////////
// Data input shift register
///////////////////////////////////////////////

always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    input_shift_reg <= 53'h0;
  else if(debug_select_i && shift_dr_i)
    input_shift_reg <= {tdi_i, input_shift_reg[52:1]};
end
///////////////////////////////////////////////


//////////////////////////////////////////////
// Debug module instantiations

// Connecting AXI module
adbg_axi_module i_dbg_axi (
                  // JTAG signals
                  .tck_i            (tck_i),
                  .module_tdo_o     (tdo_axi),
                  .tdi_i            (tdi_i),

                  // TAP states
                  .capture_dr_i     (capture_dr_i),
                  .shift_dr_i       (shift_dr_i),
                  .update_dr_i      (update_dr_i),

                  .data_register_i  (input_shift_reg),
                  .module_select_i  (module_selects[0]),
                  .top_inhibit_o    (module_inhibit[0]),
                  .rst_i            (rst_i),

        .axi_aclk(axi_aclk),
        .axi_aresetn(axi_aresetn),

        .axi_master_aw_valid(axi_master_aw_valid),
        .axi_master_aw_addr(axi_master_aw_addr),
        .axi_master_aw_prot(axi_master_aw_prot),
        .axi_master_aw_region(axi_master_aw_region),
        .axi_master_aw_len(axi_master_aw_len),
        .axi_master_aw_size(axi_master_aw_size),
        .axi_master_aw_burst(axi_master_aw_burst),
        .axi_master_aw_lock(axi_master_aw_lock),
        .axi_master_aw_cache(axi_master_aw_cache),
        .axi_master_aw_qos(axi_master_aw_qos),
        .axi_master_aw_id(axi_master_aw_id),
        .axi_master_aw_user(axi_master_aw_user),
        .axi_master_aw_ready(axi_master_aw_ready),

        .axi_master_ar_valid(axi_master_ar_valid),
        .axi_master_ar_addr(axi_master_ar_addr),
        .axi_master_ar_prot(axi_master_ar_prot),
        .axi_master_ar_region(axi_master_ar_region),
        .axi_master_ar_len(axi_master_ar_len),
        .axi_master_ar_size(axi_master_ar_size),
        .axi_master_ar_burst(axi_master_ar_burst),
        .axi_master_ar_lock(axi_master_ar_lock),
        .axi_master_ar_cache(axi_master_ar_cache),
        .axi_master_ar_qos(axi_master_ar_qos),
        .axi_master_ar_id(axi_master_ar_id),
        .axi_master_ar_user(axi_master_ar_user),
        .axi_master_ar_ready(axi_master_ar_ready),

        .axi_master_w_valid(axi_master_w_valid),
        .axi_master_w_data(axi_master_w_data),
        .axi_master_w_strb(axi_master_w_strb),
        .axi_master_w_user(axi_master_w_user),
        .axi_master_w_last(axi_master_w_last),
        .axi_master_w_ready(axi_master_w_ready),

        .axi_master_r_valid(axi_master_r_valid),
        .axi_master_r_data(axi_master_r_data),
        .axi_master_r_resp(axi_master_r_resp),
        .axi_master_r_last(axi_master_r_last),
        .axi_master_r_id(axi_master_r_id),
        .axi_master_r_user(axi_master_r_user),
        .axi_master_r_ready(axi_master_r_ready),

        .axi_master_b_valid(axi_master_b_valid),
        .axi_master_b_resp(axi_master_b_resp),
        .axi_master_b_id(axi_master_b_id),
        .axi_master_b_user(axi_master_b_user),
        .axi_master_b_ready(axi_master_b_ready)
            );

    generate  
        for (genvar i=0; i<NB_CORES; i++)
        begin
            adbg_or1k_module i_dbg_cpu_or1k (
                  // JTAG signals
                  .tck_i            (tck_i),
                  .module_tdo_o     (tdo_cpu[i]),
                  .tdi_i            (tdi_i),

                  // TAP states
                  .capture_dr_i     (capture_dr_i),
                  .shift_dr_i       (shift_dr_i),
                  .update_dr_i      (update_dr_i),

                  .data_register_i  (input_shift_reg),
                  .module_select_i  (module_selects[i+1]),
                  .top_inhibit_o    (module_inhibit[i+1]),
                  .rst_i            (rst_i),

                  // CPU signals
                  .cpu_clk_i        (cpu_clk_i[i]), 
                  .cpu_addr_o       (cpu_addr_o[i]), 
                  .cpu_data_i       (cpu_data_i[i]), 
                  .cpu_data_o       (cpu_data_o[i]),
                  .cpu_bp_i         (cpu_bp_i[i]),
                  .cpu_stall_o      (cpu_stall_o[i]),
                  .cpu_stb_o        (cpu_stb_o[i]),
                  .cpu_we_o         (cpu_we_o[i]),
                  .cpu_ack_i        (cpu_ack_i[i]),
                  .cpu_rst_o        (cpu_rst_o[i])
              );
        end
    endgenerate

   
assign select_inhibit = | module_inhibit;

/////////////////////////////////////////////////
// TDO output MUX

always @ (module_id_reg or tdo_axi or tdo_cpu)
begin
    if (module_id_reg == 0)
        tdo_o <= tdo_axi;
    else if(module_id_reg <= NB_CORES)
        tdo_o <= tdo_cpu[module_id_reg-1];
    else
        tdo_o <= 1'b0;
end


endmodule

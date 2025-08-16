`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/30/2025 08:12:42 PM
// Design Name: 
// Module Name: FLIP_FLOP
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module dff (dff_if vif);
    always @(posedge vif.clk) begin
        if (vif.rst == 1'b1) begin
            vif.dout <= 1;
        end else begin
            vif.dout <= vif.din;
        end
    end
endmodule

interface dff_if;
    logic clk;
    logic rst;
    logic din;
    logic dout;
endinterface
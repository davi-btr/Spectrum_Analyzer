// ============================================================================
//
// Permission:
//
// ============================================================================
//
// Major Functions:I2C Finite State Machine
//
// ============================================================================
//
// Revision History :
// 
// ============================================================================

// ============================================================================

// TOP LEVEL ENTRY

module Spectrum_Analyser(
    CLOCK_50,
    
    // General purpose DE2 board features
    //KEY,
    SW,
    //LEDR,
    //LEDG,
    
    // Audio CoDec physical pins
    AUD_XCK,
    AUD_BCLK,
    AUD_ADCDAT,
    AUD_ADCLRCK,
    
    // shared I2C bus
    I2C_SCLK,
    I2C_SDAT
);

/* Ports definition */
input CLOCK_50;

//input [3:0] KEY;
input [17:0] SW;
//input SD_DO;
//output [17:0] LEDR;
//output [7:0] LEDG;

output wire AUD_XCK;
output wire AUD_BCLK;
output wire AUD_ADCDAT;
output wire AUD_ADCLRCK;

output wire I2C_SCLK;
inout  wire I2C_SDAT;

// Parameters


// Internal wires
wire clk;
wire rst_n; 
/*
wire ram_wren;
wire [7:0] ram_wr_data;
wire [7:0] ram_rd_data;
wire [RAM_ADDR_BITS-1:0] ram_wr_address;
wire [RAM_ADDR_BITS-1:0] ram_rd_address;
*/
wire right_channel;

wire fft_start;
wire [15:0] buff_rd_data;
wire [9:0] buff_rd_addr;

// Internal regs
//reg key0_pressed = 0;
//reg key12_pressed = 0;

// Internal assignments
assign clk = CLOCK_50;
assign rst_n = SW[1]; // SI PUO' USARE UN BOTTONE

/* Status LED
assign LEDR[3] = buffer_active_sel;
assign LEDR[2] = audio_buffer_filled;
assign LEDR[1] = audio_buffer_empty;
assign LEDR[0] = audio_buffer_empty_ack;
*/
/* Double buffer and RAM address translation
assign ram_rd_addr[15:0] = buff_rd_addr;
assign ram_wr_addr[15:0] = buff_wr_addr;
assign ram_rd_addr[BUFFER_ADDR_BITS] = buff_active_sel;
assign ram_wr_addr[BUFFER_ADDR_BITS] = !buff_active_sel;
*/
assign right_channel = SW[0];

Codec_interface codec(
    .clk(clk),
    .rst_n(rst_n),
    
    // Audio codec physical pins
    .codec_aud_xck_o(AUD_XCK),
    .codec_aud_bclk_i(AUD_BCLK),
    .codec_aud_adcdat_i(AUD_ADCDAT),
    .codec_aud_adclrck_i(AUD_ADCLRCK),
    
    // shared I2C bus
    .codec_i2c_sclk_o(I2C_SCLK),
    .codec_i2c_sdat_io(I2C_SDAT),
    
    // Buffer interface
    .codec_buff_raddr_i(buff_rd_addr),
    .codec_buff_start_o(fft_start),
    .codec_buff_rdata_o(buff_rd_data),
	 .codec_channel_select_i(right_channel)
);

FFT_block FFT_calc (
    .clk(clk),
    .rst_n(rst_n),
    //SEGNALI PER FFT BLOCK
	 .start(),
	 .done(),
	 //interfaccia buffer
	 .address(),
	 .q()
	 //...

);

// EVENTI GLOBALI CHE CI SERVANO QUI

endmodule

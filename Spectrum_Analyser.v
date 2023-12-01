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
    
    /* General purpose DE2 board features
    KEY,
    SW,
    LEDR,
    LEDG,*/
    
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
//input [17:0] SW;
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


/* Internal wires */
wire clk;
wire rst_n; 

wire ram_wren;
wire [7:0] ram_wr_data;
wire [7:0] ram_rd_data;
wire [RAM_ADDR_BITS-1:0] ram_wr_address;
wire [RAM_ADDR_BITS-1:0] ram_rd_address;

wire buffer_active_sel;
wire [BUFFER_ADDR_BITS-1:0] buffer_wr_address;
wire [BUFFER_ADDR_BITS-1:0] buffer_rd_address;

wire aud_buff_empty;
wire aud_buff_empty_ack;
wire aud_buff_filled;

// Internal regs
//reg key0_pressed = 0;
//reg key12_pressed = 0;

// Internal assignments
//assign rst_n = !(`BUTTON_RST); // Reset is active low

// Status LED
assign LEDR[3] = buffer_active_sel;
assign LEDR[2] = audio_buffer_filled;
assign LEDR[1] = audio_buffer_empty;
assign LEDR[0] = audio_buffer_empty_ack;

// Double buffer and RAM address translation
assign ram_rd_addr[BUFFER_ADDR_BITS-1:0] = buff_rd_addr;
assign ram_wr_addr[BUFFER_ADDR_BITS-1:0] = buff_wr_addr;
assign ram_rd_addr[BUFFER_ADDR_BITS] = buff_active_sel;
assign ram_wr_addr[BUFFER_ADDR_BITS] = !buff_active_sel;

MAIN_PLL main_pll(	//DA SETTARE
    .inclk0(CLOCK_50),
    .c0(clk) /* Set clk to 200 MHz */
);

Codec_interface codec(
    .clk(clk),
    .rst_n(rst_n),
    
    // Audio codec physical pins
    .codec_aud_xck_o(AUD_XCK),
    .codec_aud_bclk_o(AUD_BCLK),
    .codec_aud_adcdat_i(AUD_ADCDAT),
    .codec_aud_adclrck_o(AUD_ADCLRCK),
    
    // shared I2C bus
    .codec_i2c_sclk_o(I2C_SCLK),
    .codec_i2c_sdat_io(I2C_SDAT),
    
    // Buffer interface
    .codec_buffer_addr_o(buff_wr_addr),
    .codec_buffer_sel_o(buff_active_sel),
    .codec_buffer_data_o(ram_wr_data),
    .codec_buffer_filled_i(aud_buff_filled),
    .codec_buffer_empty_o(aud_buff_empty),
    .codec_buffer_empty_ack_i(aud_buff_empty_ack),
);

RAM_dualport ram_dualport(	//TUTTA DA CAPIRE E FARE
	.clock(!clk), /* RAM writes on rising edge if clk not inverted. */
	.data(ram_wr_data),
	.rdaddress(ram_rd_addr),
	.wraddress(ram_wr_addr),
	.wren(ram_wren),
	.q(ram_rd_data)
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
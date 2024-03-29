create_clock -name CLOCK_50 -period 20 [get_ports CLOCK_50]
#create_clock -name fftclk_div_cnt -period 40
#create_clock -name i2c_slowclk -period 4000 [get_ports i2c_slowclk]
create_clock -name AUD_BCLK -period 326 [get_ports AUD_BCLK]
#create_clock -name VGA_HS_o -period 33600 [get_ports VGA_HS_o]
#set_false_path -from [get_ports rst_n] -to [get_clocks CLOCK_50]
#create_clock -name clkfft -period 40.000 -waveform {0 20} [get_registers {fftclk_div_cnt}]
#create_generated_clock -name clkfft -source [get_pins Spectrum_Analyzer/CLOCK_50] -divide_by 2 [get_pins Spectrum_Analyzer/fftclk_div_cnt]
#create_clock -name vga_hs -period 326.000 -waveform {0 163} [get_registers {vga_block:vga_output|vga_controller:vga_display|vga_time_generator:vga|VGA_HS_o}]
create_clock -name i2cslow -period 4000 -waveform {0 2000} [get_registers {Codec_interface:codec|codec_init:config_FSM|i2c_slowclk}]
#create_clock -name fff -period 10.000 [get_registers {Codec_interface:codec|codec_init:config_FSM|i2c_slowclk}]
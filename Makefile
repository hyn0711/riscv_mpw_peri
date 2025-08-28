# Makefile for Icarus Verilog Simulation with SystemVerilog support

# Top-level testbench module
TOP_MODULE = tb_peri_top

# Source files
SRC = ./testbench/tb_peri_top.sv \
	  ./peri_module/peri_top.sv \
	  ./peri_module/peri_controller.sv \
	  ./peri_module/eFlash_row_driver.sv \
	  ./peri_module/eFlash_col_driver.sv \
	  ./peri_module/output_buffer/accum_buffer.sv \
	  ./peri_module/output_buffer/eFlash_to_encoder.sv \
	  ./peri_module/output_buffer/mapping_group_shift.sv \
	  ./peri_module/output_buffer/mapping_group_top.sv \
	  ./peri_module/output_buffer/output_buffer_top.sv \
	  ./peri_module/output_buffer/output_buffer_read_mode.sv 

# output binary
OUT = peri.out

#Waveform file
WAVE = peri_top_wave.vcd

# Default target: build and run
all: run

# Compile
$(OUT): $(SRC)
	iverilog -g2012 -o $(OUT) -s $(TOP_MODULE) $(SRC)

run: $(OUT)
	vvp $(OUT)

wave: run
	gtkwave $(WAVE)

clean: 
	rm -f $(OUT) $(WAVE)
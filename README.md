# fir-filter-16bit-8x8-m9k
WIP on FIR filter, which does parallel calculation of 8 16-bit data samples with 8 16-bit fir samples within 3 clock cycles.  
Designed with `SystemVerilog HDL` in `Quartus` for `Altera Cyclone IV` family.  
Impulse and buffer are stored in `M9K` memory blocks.

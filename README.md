# fir-filter-16bit-8x8-m9k
WIP on FIR filter, which does calculation of up to eight 16-bit raw samples portion. Up to 64 operations (multiplication + accumulation) per 1 clock cycle in parallel. Number of operation cycles = FIR length / samples number + 4 delay cycles + 1 setup cycle. 
Designed with `SystemVerilog HDL` in `Quartus` for `Altera Cyclone IV` family.  
Impulse and buffer are stored in `M9K` memory blocks.

#Hardware
* `EasyFPGA A2.2` board [documentation](https://forum.maxiol.com/lofiversion/index.php/t5332.html)

#Pinout
* CLK -> PIN_23
* N_RESET -> PIN_25
* MISO -> PIN_106
* MOSI -> PIN_105
* SCK -> PIN_104
* SS -> PIN_103

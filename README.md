# fir-filter-16bit-8x8-m9k
WIP on FIR filter, which does calculation of up to eight 16-bit raw samples portion. Up to 64 operations (multiplication + accumulation) per 1 clock cycle in parallel. Number of operation cycles = FIR length / samples number + 4 delay cycles + 1 setup cycle. 
Designed with `SystemVerilog HDL` in `Quartus` for `Altera Cyclone IV` family.  
Impulse and buffer are stored in `M9K` memory blocks.

#Hardware
* `Qmtech Cyclone IV EP4CE55` board [documentation](https://github.com/ChinaQMTECH/QM_CYCLONE_IV_EP4CE55)

#Pinout
* CLK -> PIN_T2
* N_RESET -> PIN_W6
* MISO -> PIN_M20
* MOSI -> PIN_M19
* SCK -> PIN_N20
* SS -> PIN_N19
* FIR_DI -> PIN_B22
* FIR_SCK -> PIN_B21
* FIR_LOAD -> PIN_C22
* READY -> PIN_C21

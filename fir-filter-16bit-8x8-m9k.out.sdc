## Generated SDC file "fir-filter-16bit-8x8-m9k.out.sdc"

## Copyright (C) 2020  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and any partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details, at
## https://fpgasoftware.intel.com/eula.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 20.1.0 Build 711 06/05/2020 SJ Lite Edition"

## DATE    "Mon Mar 29 23:39:09 2021"

##
## DEVICE  "EP4CE6E22C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clkIn} -period 50MHz -waveform { 0.000 10.000 } [get_ports {clkIn}]


#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {clkIn}] -rise_to [get_clocks {clkIn}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clkIn}] -fall_to [get_clocks {clkIn}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clkIn}] -rise_to [get_clocks {clkIn}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clkIn}] -fall_to [get_clocks {clkIn}]  0.020  


#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -clock { clkIn } 2 [get_ports *]


#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -clock { clkIn } 1.5 [get_ports *]


#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************


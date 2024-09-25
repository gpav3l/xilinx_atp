#
# *********************************************************************
#
# Script to assist students running the GNU dissassembly tool for the
# MPSoC_APU/FP_and_SIMD lab
#
# WK  2/22/2016
#
# *********************************************************************
#

# load the standard helper file
set xilToolsInstalDir ~/Tools/
set osIsLinux 1

if {$tcl_platform(os) != "Linux"} {
	set osIsLinux 0
} 

if {$osIsLinux} {
	source ~/training/tools/helper.tcl
} else {
	source c:/training/tools/helper.tcl
}
# define shorthands
set projName             dot_product_app
set VERSION              [getNewestXilinxVersion]

if {$osIsLinux} {
	set workDir              /home/xilinx/training/MPSoC_APU/lab
	set dissassemblerToolLoc $xilToolsInstalDir/SDK/$VERSION/gnu/aarch64/lin/aarch64-none/bin
} else {
	set workDir              c:/training/MPSoC_APU/lab
	set dissassemblerToolLoc c:/Xilinx/SDK/$VERSION/gnu/aarch64/nt/aarch64-none/bin
}


set outputName           dot_product_app_O3.s
set src                  $workDir/$projName/Debug/$projName.elf 

#
# Welcome the user
puts "Dissassembling $projName with optimization"
       
#
# run the dis-assembler
if {$osIsLinux} {
	exec $dissassemblerToolLoc/aarch64-none-elf-objdump -D $src > $workDir/$outputName
} else {
	exec $dissassemblerToolLoc/aarch64-none-elf-objdump.exe -D $src > $workDir/$outputName
}


#
# Done
puts "Done with dissassembly!"
# 

#!/bin/bash
qemu-system-aarch64 -nographic -M arm-generic-fdt -dtb /home/xilinx/training/QEMU_BareMetal_App/support/zynqmp-qemu-arm.dtb -device loader,file=/home/xilinx/training/QEMU_BareMetal_App/lab/hello_world/Debug/hello_world.elf,cpu-num=0 -device loader,addr=0xfd1a0104,data=0x8000000e,data-len=4 

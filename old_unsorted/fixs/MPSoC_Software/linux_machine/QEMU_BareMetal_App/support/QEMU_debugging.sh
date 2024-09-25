#!/bin/bash
qemu-system-aarch64 -nographic -M arm-generic-fdt \
-dtb /home/xilinx/training/QEMU_BareMetal_App/support/zynqmp-qemu-arm.dtb \
-gdb tcp::1534

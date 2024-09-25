#
# renameImage.sh
#
#    Renames two of the images created by the petalinux-create command from the ZCU102 BSP
#    for use in the MPSoC_HSV lab. The linux image with the Xen Hypervisor is renamed as Dom0,
#    and the linux image without the Xen Hypervisor is renamed as DomU
#
# History
#    2018-05-9  - HW - updated for 2018.1
#    2017-11-01 - HW - updated for 2017.3
#    2017-07-05 - HW - Created for 2017.1
#

# move to where the images are kept
cd ~/training/MPSoC_HSV/lab/ZCU102/pre-built/linux/images

# rename the items for Dom0 (device tree blob, linux image, file system, kernel (ub)
mv xen-Image Dom0-Image
mv xen-qemu.dtb Dom0.dtb
mv xen-rootfs.cpio.gz.u-boot Dom0-rootfs.cpio.gz.u-boot

# copy the DomU configuration file and DomU-Image provided in support into the prebuilt directory
#cp ~/training/MPSoC_HSV/support/DomU.cfg .
#cp ~/training/MPSoC_HSV/support/DomU-Image .

#Changing the directory to the root of project directory
cd ~/training/MPSoC_HSV/lab/ZCU102
# done!
echo done! images renamed

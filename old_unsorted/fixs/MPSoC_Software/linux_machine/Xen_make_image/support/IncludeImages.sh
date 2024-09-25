#
#IncludeImages.sh
#
# Created by : Harshal Wadke 
# Date: 11/11/2017
#
#
#


#Copy the Xen Images from the support
rm ~/training/Xen_make_image/lab/ZCU102/pre-built/linux/images/Image
rm ~/training/Xen_make_image/lab/ZCU102/pre-built/linux/images/xen.ub
rm ~/training/Xen_make_image/lab/ZCU102/pre-built/linux/images/system.dtb


cp ~/training/Xen_make_image/support/Image /media/xilinx/training/Xen_make_image/lab/ZCU102/pre-built/linux/images
cp ~/training/Xen_make_image/support/xen.ub /media/xilinx/training/Xen_make_image/lab/ZCU102/pre-built/linux/images
cp ~/training/Xen_make_image/support/rootfs.cpio.gz.u-boot /media/xilinx/training/Xen_make_image/lab/ZCU102/pre-built/linux/images
cp ~/training/Xen_make_image/support/system.dtb /media/xilinx/training/Xen_make_image/lab/ZCU102/pre-built/linux/images

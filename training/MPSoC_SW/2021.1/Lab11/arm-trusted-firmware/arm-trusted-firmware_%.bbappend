FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
 
SRC_URI_append = " file://0001-arm-trusted-firmware.patch"

EXTRA_OEMAKE_append = "  ZYNQMP_WDT_RESTART=1"


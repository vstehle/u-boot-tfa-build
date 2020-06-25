
DTB_TARGET   := src/arm64/marvell/armada-8040-mcbin.dtb

UBOOT_CONFIG := mvebu_mcbin-88f8040

TFA_PLAT     := a80x0_mcbin
TFA_EXTRA    := MV_DDR_PATH=${CURDIR}/mv-ddr USE_COHERENT_MEM=0 SCP_BL2=${CURDIR}/binaries-marvell/mrvl_scp_bl2.img BL33=${UBOOT_OUTPUT}/u-boot.bin all fip

FLASH_EXTRA  := seek=1

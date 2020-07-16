
DTB_TARGET   := src/arm64/marvell/armada-8040-mcbin.dtb

UBOOT_EXTRA := EXT_OS_DTB=${DT_PATH}/${DTB_TARGET}

TFA_PLAT     := a80x0_mcbin
TFA_EXTRA    := MV_DDR_PATH=${CURDIR}/mv-ddr USE_COHERENT_MEM=0 SCP_BL2=${CURDIR}/binaries-marvell/mrvl_scp_bl2.img

FLASH_EXTRA  := seek=1

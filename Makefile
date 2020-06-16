export CROSS_COMPILE=aarch64-linux-gnu-
export MAKE=make

TARGET ?= mcbin

mcbin_DTB_TARGET=src/arm64/marvell/armada-8040-mcbin.dtb
mcbin_UBOOT_TARGET=mvebu_mcbin-88f8040
mcbin_TFA_PLAT=a80x0_mcbin
mcbin_SCP_BL2=${CURDIR}/binaries-marvell/mrvl_scp_bl2.img

rockpro64_DTB_TARGET=src/arm64/rockchip/rk3399-rockpro64-v2.dtb
rockpro64_UBOOT_TARGET=rockpro64-rk3399
rockpro64_TFA_PLAT=rk3399

# Grab the platform specific variables into generic versions
export DTB_TARGET=${${TARGET}_DTB_TARGET}
export TFA_PLAT=${${TARGET}_TFA_PLAT}
export TFA_EXTRA=${${TARGET}_TFA_EXTRA}
export UBOOT_TARGET=${${TARGET}_UBOOT_TARGET}
export UBOOT_EXTRA=${${TARGET}_UBOOT_EXTRA}

export DT_PATH=${CURDIR}/devicetree-rebasing
export UBOOT_PATH=${CURDIR}/u-boot
export UBOOT_OUTPUT=${UBOOT_PATH}/build-${UBOOT_TARGET}
export TFA_PATH=${CURDIR}/arm-trusted-firmware
export TFA_FLASH_IMAGE=${TFA_PATH}/build/${TFA_PLAT}/release/flash-image.bin

mcbin_TFA_EXTRA=MV_DDR_PATH=${CURDIR}/mv-ddr USE_COHERENT_MEM=0 SCP_BL2=${${TARGET}_SCP_BL2} BL33=${UBOOT_OUTPUT}/u-boot.bin all fip
rockpro64_UBOOT_EXTRA=BL31=${TFA_PATH}/build/${TFA_PLAT}/release/bl31/bl31.elf

# Some platforms build TFA then U-Boot; some the other way around. Locate both images
export BL31=${TFA_PATH}/build/${TFA_PLAT}/release/bl31/bl31.elf
export BL33=${UBOOT_PATH}/u-boot.bin

all: dtb u-boot tfa

.PHONY: dtb u-boot tfa clean

clean:
	cd ${UBOOT_PATH} && make mrproper
	cd ${TFA_PATH} && git clean -fdx
	cd ${CURDIR}/mv-ddr && git clean -fdx

dtb:
	cd ${DT_PATH} && ${MAKE} ${DTB_TARGET}

u-boot: 
	mkdir -p ${UBOOT_OUTPUT}
	cd ${UBOOT_PATH} && ${MAKE} KBUILD_OUTPUT=${UBOOT_OUTPUT} ${UBOOT_TARGET}_defconfig && ${MAKE} ${UBOOT_EXTRA} KBUILD_OUTPUT=${UBOOT_OUTPUT} -j4

atf: u-boot
	cd ${TFA_PATH} && ${MAKE} LOG_LEVEL=20 PLAT=${TFA_PLAT} ${TFA_EXTRA} all fip

flash-to-sd:
	sudo dd if=${TFA_FLASH_IMAGE} of=${FLASH_DEVICE} conv=fdatasync status=progress

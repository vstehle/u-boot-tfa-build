export CROSS_COMPILE=aarch64-linux-gnu-
export MAKE=make

TARGET ?= mcbin

mcbin_UBOOT_TARGET=mvebu_mcbin-88f8040
mcbin_TFA_PLAT=a80x0_mcbin
mcbin_SCP_BL2=${CURDIR}/binaries-marvell/mrvl_scp_bl2.img
mcbin_TFA_EXTRA=MV_DDR_PATH=${CURDIR}/mv-ddr

rockpro64_UBOOT_TARGET=rockpro64-rk3399
rockpro64_TFA_PLAT=rk3399

# Grab the platform specific variables into generic versions
export TFA_PLAT=${${TARGET}_TFA_PLAT}
export TFA_EXTRA=${${TARGET}_TFA_EXTRA}
export UBOOT_TARGET=${${TARGET}_UBOOT_TARGET}

export UBOOT_PATH=${CURDIR}/u-boot
export TFA_PATH=${CURDIR}/arm-trusted-firmware
export TFA_FLASH_IMAGE=${TFA_PATH}/build/${TFA_PLAT}/release/flash-image.bin

# Some platforms build TFA then U-Boot; some the other way around. Locate both images
export BL31=${TFA_PATH}/build/${TFA_PLAT}/release/bl31/bl31.elf
export BL33=${UBOOT_PATH}/u-boot.bin

all: u-boot atf

.PHONY: u-boot arm-trusted-firmware clean

clean:
	cd ${UBOOT_PATH} && make mrproper
	cd ${MV_DDR} && git clean -fdx
	cd ${ATF_PATH} && git clean -fdx 

u-boot: 
	cd ${UBOOT_PATH} && ${MAKE} ${UBOOT_TARGET}_defconfig && ${MAKE} -j4

atf: u-boot
	cd ${TFA_PATH} && ${MAKE} LOG_LEVEL=20 USE_COHERENT_MEM=0 SCP_BL2=${${TARGET}_SCP_BL2} PLAT=${TFA_PLAT} ${TFA_EXTRA} all fip

flash-to-sd:
	sudo dd if=${TFA_FLASH_IMAGE} of=${FLASH_DEVICE} conv=fdatasync status=progress

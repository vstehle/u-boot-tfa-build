# SPDX-License-Identifier: GPL-2.0+
#
# Copyright (C) Arm Limited, 2020

ifndef TARGET
  $(error TARGET is not set)
endif
ifndef UBOOT_OUTPUT
  $(error UBOOT_OUTPUT is not set)
endif

export CROSS_COMPILE=aarch64-linux-gnu-
MAKE=make

all: # Nothing by default

# Include the 
include $(UBOOT_OUTPUT)/.config

ifdef CONFIG_ROCKCHIP_RK3399
TFA_PLAT := rk3399
UBOOT_EXTRA := BL31=$(TFA_PATH)/build/$(TFA_PLAT)/release/bl31/bl31.elf
FLASH_IMAGE := $(UBOOT_OUTPUT)/flash_image.bin
DTB_TARGET := src/arm64/$(CONFIG_DEFAULT_FDT_FILE)
u-boot: tfa-bl31

include $(CURDIR)/scripts/rk3399.mk
endif

ifdef CONFIG_ARMADA_8K
include scripts/mvebu-armada-8k.mk
DTB_TARGET := src/arm64/marvell/$(CONFIG_DEFAULT_DEVICE_TREE).dtb
ifeq ($(CONFIG_DEFAULT_DEVICE_TREE),"armada-8040-mcbin")
TFA_PLAT := a80x0_mcbin
endif
endif

ifndef TFA_PLAT
  $(error TARGET=$(TARGET) is not yet supported by this tool; $(CONFIG_DEFAULT_DEVICE_TREE))
endif

# Grab the platform specific variables into generic versions

UBOOT_EXTRA ?= EXT_DTB=$(DT_PATH)/$(DTB_TARGET)

FLASH_IMAGE ?= $(TFA_PATH)/build/$(TFA_PLAT)/release/flash-image.bin

.PHONY: dtb u-boot clean

clean:
	cd ${UBOOT_PATH} && make mrproper
	cd ${TFA_PATH} && git clean -fdx
	cd ${CURDIR}/mv-ddr && git clean -fdx

dtb:
	${MAKE} -C ${DT_PATH} ${DTB_TARGET}
	fdtput ${DT_PATH}/${DTB_TARGET} -t s / u-boot-ver `cd ${UBOOT_PATH} && git describe`
	fdtput ${DT_PATH}/${DTB_TARGET} -t s / tfa-ver `cd ${TFA_PATH} && git describe`
	fdtput ${DT_PATH}/${DTB_TARGET} -t s / dt-ver `cd ${DT_PATH} && git describe`
	#fdtput ${DT_PATH}/${DTB_TARGET} -t x /ap806/config-space@f0000000/serial@512000 clock-frequency 0xbebc200

u-boot: export KBUILD_OUTPUT=$(UBOOT_OUTPUT)
u-boot: dtb
	${MAKE} -C ${UBOOT_PATH} ${UBOOT_EXTRA} -j4

tfa-bl31: export PLAT=$(TFA_PLAT)
tfa-bl31:
	${MAKE} -C ${TFA_PATH} LOG_LEVEL=20 ${TFA_EXTRA} bl31

tfa-fip: export BL33=$(UBOOT_OUTPUT)/u-boot.bin
tfa-fip: export PLAT=$(TFA_PLAT)
tfa-fip: u-boot ${TFA_DEPS}
	${MAKE} -C ${TFA_PATH} LOG_LEVEL=20 ${TFA_EXTRA} all fip

flash-to-sd:
	sudo dd if=${FLASH_IMAGE} of=${FLASH_DEVICE} ${FLASH_EXTRA} conv=fdatasync status=progress

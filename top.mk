# SPDX-License-Identifier: GPL-2.0+
#
# Copyright (C) Arm Limited, 2020

ifndef TARGET
  $(error TARGET is not set)
endif

export CROSS_COMPILE=aarch64-linux-gnu-
MAKE=make

# Set some defaults that can be overridden by the target  makefile include
DT_PATH      := $(CURDIR)/devicetree-rebasing
TFA_PLAT     := $(TARGET)
TFA_PATH     := $(CURDIR)/arm-trusted-firmware
UBOOT_PATH   := $(CURDIR)/u-boot
UBOOT_OUTPUT := $(UBOOT_PATH)/build-$(TARGET)

all: u-boot tfa

# Include the platform specific Makefile
include scripts/${TARGET}.mk

# Grab the platform specific variables into generic versions

UBOOT_EXTRA ?= EXT_DTB=$(DT_PATH)/$(DTB_TARGET)
UBOOT_DEPS ?= dtb
TFA_DEPS ?= u-boot

FLASH_IMAGE ?= $(TFA_PATH)/build/$(TFA_PLAT)/release/flash-image.bin

.PHONY: dtb u-boot tfa clean

clean:
	cd ${UBOOT_PATH} && make mrproper
	cd ${TFA_PATH} && git clean -fdx
	cd ${CURDIR}/mv-ddr && git clean -fdx

dtb:
	cd ${DT_PATH} && ${MAKE} ${DTB_TARGET}
	fdtput ${DT_PATH}/${DTB_TARGET} -t s / u-boot-ver `cd ${UBOOT_PATH} && git describe`
	fdtput ${DT_PATH}/${DTB_TARGET} -t s / tfa-ver `cd ${TFA_PATH} && git describe`
	fdtput ${DT_PATH}/${DTB_TARGET} -t s / dt-ver `cd ${DT_PATH} && git describe`
	#fdtput ${DT_PATH}/${DTB_TARGET} -t x /ap806/config-space@f0000000/serial@512000 clock-frequency 0xbebc200

u-boot: export KBUILD_OUTPUT=$(UBOOT_OUTPUT)
u-boot: dtb ${UBOOT_DEPS}
	mkdir -p ${UBOOT_OUTPUT}
	${MAKE} -C ${UBOOT_PATH} ${UBOOT_EXTRA} ${TARGET}_defconfig
	${MAKE} -C ${UBOOT_PATH} ${UBOOT_EXTRA} -j4

tfa: export PLAT=$(TFA_PLAT)
tfa: ${TFA_DEPS} ${TFA_PATH}/CACHETAG.DIR
	cd ${TFA_PATH} && ${MAKE} LOG_LEVEL=20 ${TFA_EXTRA}

flash-to-sd:
	sudo dd if=${FLASH_IMAGE} of=${FLASH_DEVICE} ${FLASH_EXTRA} conv=fdatasync status=progress

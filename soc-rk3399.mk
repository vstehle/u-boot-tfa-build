# SPDX-License-Identifier: GPL-2.0+
#
# Copyright (C) Arm Limited, 2020
#
# Build config for RockPro64
# Inspired by https://stikonas.eu/wordpress/2019/09/15/blobless-boot-with-rockpro64/
#
# Flashing via USB requires rkdeveloptool. You can find it here:
# rkdeveloptool: https://github.com/rockchip-linux/rkdeveloptool.git

FLASH_IMAGE_DEPS := u-boot/all
TFA_PLAT := $(CONFIG_SYS_SOC)
OPTEE_PLATFORM := rockchip
OPTEE_EXTRA += PLATFORM_FLAVOR=rk3399
FLASH_IMAGE := $(UBOOT_OUTPUT)/flash_image.bin

RKDEVELOPTOOL ?= rkdeveloptool

ifeq ($(CONFIG_OPTEE),y)
UBOOT_EXTRA += TEE=$(OPTEE_OUTPUT)/arm-plat-rockchip/core/tee.elf
u-boot/all: optee_os/all
endif

UBOOT_EXTRA += BL31=$(TFA_OUTPUT)/$(TFA_PLAT)/release/bl31/bl31.elf

all: sdimage
sdimage:
	dd if=/dev/zero of=$(SD_IMAGE) count=$$((32*1024*1024>>9))
	/sbin/sgdisk -g $(SD_IMAGE)
	/sbin/sgdisk -n 1:: $(SD_IMAGE)
	dd if=${UBOOT_OUTPUT}/idbloader.img of=$(SD_IMAGE) seek=64
	dd if=${UBOOT_OUTPUT}/u-boot.itb of=$(SD_IMAGE) seek=16384

flash-usb: $(UBOOT_OUTPUT)/idbloader.img $(UBOOT_OUTPUT)/u-boot.itb
	$(RKDEVELOPTOOL) db MiniLoaderAll.bin && sleep 0.25
	$(RKDEVELOPTOOL) wl 0x40 $(UBOOT_OUTPUT)/idbloader.img
	$(RKDEVELOPTOOL) wl 0x4000 $(UBOOT_OUTPUT)/u-boot.itb
	$(RKDEVELOPTOOL) rd

# SPDX-License-Identifier: GPL-2.0+
#
# Copyright (C) Arm Limited, 2020
#
# Build config for RockPro64
# Inspired by https://stikonas.eu/wordpress/2019/09/15/blobless-boot-with-rockpro64/

DTB_TARGET := src/arm64/rockchip/rk3399-rockpro64-v2.dtb

TFA_PLAT   := rk3399
TFA_EXTRA  := bl31
TFA_DEPS   := dtb

UBOOT_CONFIG := rockpro64-rk3399
UBOOT_EXTRA  := BL31=${TFA_PATH}/build/${TFA_PLAT}/release/bl31/bl31.elf
UBOOT_DEPS   := tfa

FLASH_IMAGE := ${UBOOT_OUTPUT}/flash_image.bin

rockpro64-sd:
	sudo dd if=${UBOOT_OUTPUT}/idbloader.img of=${FLASH_DEVICE} seek=64 conv=fdatasync status=progress
	sudo dd if=${UBOOT_OUTPUT}/u-boot.itb of=${FLASH_DEVICE} seek=16384 conv=fdatasync status=progress

# SPDX-License-Identifier: GPL-2.0+
#
# Copyright (C) Arm Limited, 2020
#
# Build config for RockPro64
# Inspired by https://stikonas.eu/wordpress/2019/09/15/blobless-boot-with-rockpro64/

FLASH_IMAGE_DEPS := u-boot/all

sdimage:
	dd if=/dev/zero of=$(SD_IMAGE) seek=32M count=0
	/sbin/sgdisk -g $(SD_IMAGE)
	/sbin/sgdisk -n 1:: $(SD_IMAGE)
	dd if=${UBOOT_OUTPUT}/idbloader.IMAGE of=$(SD_IMG) seek=64
	dd if=${UBOOT_OUTPUT}/u-boot.itb of=$(SD_IMAGE) seek=16384

# SPDX-License-Identifier: GPL-2.0+
#
# Copyright (C) Arm Limited, 2020
#
# Build config for RockPro64
# Inspired by https://stikonas.eu/wordpress/2019/09/15/blobless-boot-with-rockpro64/

TFA_EXTRA += SCP_BL2=${CURDIR}/binaries-marvell/mrvl_scp_bl2.img
TFA_EXTRA += MV_DDR_PATH=${CURDIR}/mv-ddr
TFA_EXTRA += USE_COHERENT_MEM=0

sdcard-image: SD_IMG=$(CURDIR)/$(TARGET)-sdcard.img
sdcard-image: u-boot
	dd if=/dev/zero of=$(SD_IMG) seek=32M count=0
	echo "label: dos" | /sbin/sfdisk $(SD_IMG)
	dd if=${FLASH_IMAGE} of=$(SD_IMG) seek=1

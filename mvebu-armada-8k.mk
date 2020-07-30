# SPDX-License-Identifier: GPL-2.0+
#
# Copyright (C) Arm Limited, 2020

TFA_EXTRA += SCP_BL2=${CURDIR}/binaries-marvell/mrvl_scp_bl2.img
TFA_EXTRA += MV_DDR_PATH=${CURDIR}/mv-ddr
TFA_EXTRA += USE_COHERENT_MEM=0

sdimage: $(FLASH_IMAGE)
	dd if=/dev/zero of=$(SD_IMAGE) count=$$((128*1024*1024>>9))
	echo "label: dos\n$$(($(ESP_OFFSET)>>9)) - 0xef -" | /sbin/sfdisk $(SD_IMAGE)
	dd if=${FLASH_IMAGE} of=$(SD_IMAGE) seek=1 conv=notrunc
	#dd if=esp.img of=$(SD_IMAGE) seek=$$(($(ESP_OFFSET)>>9)) conv=notrunc

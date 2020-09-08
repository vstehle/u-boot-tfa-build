# SPDX-License-Identifier: GPL-2.0+
#
# Copyright (C) Arm Limited, 2020

$(info Using Marvell Armada 8K support from board-$(subst ",,$(CONFIG_SYS_BOARD)).mk)

OPTEE_PLATFORM=marvell-armada7k8k

# Use precompiled Marvel BL2 binary
TFA_EXTRA += SCP_BL2=${CURDIR}/binaries-marvell/mrvl_scp_bl2.img

# Use the Marvell DDR training from an external repo
TFA_EXTRA += MV_DDR_PATH=${CURDIR}/mv-ddr
TFA_EXTRA += USE_COHERENT_MEM=0

ifeq ($(CONFIG_DEFAULT_DEVICE_TREE),"armada-8040-mcbin")
TFA_PLAT := a80x0_mcbin
endif

mv-ddr-clean:
	cd $(CURDIR)/mv-ddr && git clean -fdx

clean: mv-ddr-clean
mrproper: mv-ddr-clean
distclean: mv-ddr-clean

sdimage: $(FLASH_IMAGE)
	dd if=/dev/zero of=$(SD_IMAGE) count=$$((128*1024*1024>>9))
	echo "label: dos\n$$(($(ESP_OFFSET)>>9)) - 0xef -" | /sbin/sfdisk $(SD_IMAGE)
	dd if=${FLASH_IMAGE} of=$(SD_IMAGE) seek=1 conv=notrunc
	#dd if=esp.img of=$(SD_IMAGE) seek=$$(($(ESP_OFFSET)>>9)) conv=notrunc

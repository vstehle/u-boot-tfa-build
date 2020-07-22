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
SD_IMG=$(CURDIR)/$(TARGET)-sdcard.img

all: tfa-fip # Nothing by default

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

#UBOOT_EXTRA ?= EXT_DTB=$(DT_PATH)/$(DTB_TARGET)

FLASH_IMAGE ?= $(TFA_PATH)/build/$(TFA_PLAT)/release/flash-image.bin

ESP_SIZE ?= $$((64*1024*1024))
ESP_OFFSET ?= $$((4*1024*1024))

SCT_VERSION:=UEFI2.6SCTII_Final_Release

.PHONY: dtb u-boot clean

dtb:
	${MAKE} -C ${DT_PATH} ${DTB_TARGET}
	fdtput ${DT_PATH}/${DTB_TARGET} -t s / u-boot-ver `cd ${UBOOT_PATH} && git describe`
	fdtput ${DT_PATH}/${DTB_TARGET} -t s / tfa-ver `cd ${TFA_PATH} && git describe`
	fdtput ${DT_PATH}/${DTB_TARGET} -t s / dt-ver `cd ${DT_PATH} && git describe`
	#fdtput ${DT_PATH}/${DTB_TARGET} -t x /ap806/config-space@f0000000/serial@512000 clock-frequency 0xbebc200

u-boot: export KBUILD_OUTPUT=$(UBOOT_OUTPUT)
u-boot: dtb
	${MAKE} -C ${UBOOT_PATH} ${UBOOT_EXTRA} -j4

tfa-bl31:
	${MAKE} -C ${TFA_PATH} LOG_LEVEL=20 PLAT=$(TFA_PLAT) ${TFA_EXTRA} bl31

tfa-fip: u-boot ${TFA_DEPS}
	${MAKE} -C ${TFA_PATH} LOG_LEVEL=20 PLAT=$(TFA_PLAT) BL33=$(UBOOT_OUTPUT)/u-boot.bin ${TFA_EXTRA} all fip

sd.img: $(SD_IMG)

flash-sd: $(SD_IMG)
	sudo dd if=${SD_IMG} of=${FLASH_DEVICE} conv=fdatasync status=progress

Shell.efi:
	wget https://github.com/tianocore/edk2/raw/UDK2018/ShellBinPkg/UefiShell/AArch64/Shell.efi

$(SCT_VERSION).zip:
	wget http://www.uefi.org/sites/default/files/resources/$(SCT_VERSION).zip

UEFISCT/.done: $(SCT_VERSION).zip
	unzip -f $(SCT_VERSION).zip UEFISCT.zip
	unzip -f UEFISCT.zip
	touch $@

esp.tree/.done: scripts/main.mk Shell.efi $(SCT_VERSION).zip
	mkdir -p esp.tree/efi/boot
	mkdir -p esp.tree/UEFISCT
	cp Shell.efi \
	   $(DT_PATH)/$(DTB_TARGET) \
	   $(UBOOT_OUTPUT)/lib/efi_selftest/efi_selftest_miniapp_return.efi \
	   $(UBOOT_OUTPUT)/lib/efi_selftest/efi_selftest_miniapp_exception.efi \
	   $(UBOOT_OUTPUT)/lib/efi_selftest/efi_selftest_miniapp_exit.efi \
	   $(UBOOT_OUTPUT)/lib/efi_loader/helloworld.efi esp.tree/
	cp -r UEFISCT/SctPackageAARCH64/* esp.tree/UEFISCT
	touch $@

esp.img: scripts/main.mk Shell.efi esp.tree/.done
	dd if=/dev/zero of=esp.img count=$$(($(ESP_SIZE) >> 9))
	/sbin/mkfs.fat esp.img
	mcopy -i esp.img -s esp.tree/* ::

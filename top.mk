# SPDX-License-Identifier: GPL-2.0+
#
# Copyright (C) Arm Limited, 2020

ifndef TARGET
  $(error TARGET is not set)
endif

# Set some defaults that can be overridden by the target  makefile include
export DT_PATH    := $(CURDIR)/devicetree-rebasing
export TFA_PATH   := $(CURDIR)/arm-trusted-firmware
export UBOOT_PATH := $(CURDIR)/u-boot
export UBOOT_OUTPUT := $(CURDIR)/u-boot/build-$(TARGET)

all: tfa-fip

clean:
	cd $(UBOOT_PATH) && make mrproper
	cd $(UBOOT_PATH) && make KBUILD_OUTPUT=$(UBOOT_OUTPUT) clean
	cd $(TFA_PATH) && git clean -fdx
	cd $(CURDIR)/mv-ddr && git clean -fdx

$(UBOOT_OUTPUT)/.config:
	mkdir -p $(UBOOT_OUTPUT)
	$(MAKE) -C $(UBOOT_PATH) KBUILD_OUTPUT=$(UBOOT_OUTPUT) $(TARGET)_defconfig
	echo CONFIG_CMD_BOOTEFI_HELLO=y >> $(UBOOT_OUTPUT)/.config
	echo CONFIG_CMD_BOOTEFI_SELFTEST=y >> $(UBOOT_OUTPUT)/.config
	echo CONFIG_CMD_NVEDIT_EFI=y >> $(UBOOT_OUTPUT)/.config
	echo CONFIG_CMD_EFIDEBUG=y >> $(UBOOT_OUTPUT)/.config
	echo CONFIG_CMD_GPT=y >> $(UBOOT_OUTPUT)/.config
	$(MAKE) -C $(UBOOT_PATH) KBUILD_OUTPUT=$(UBOOT_OUTPUT) olddefconfig

%: $(UBOOT_OUTPUT)/.config
	$(MAKE) -f scripts/main.mk TARGET=$(TARGET) $@

.PHONY: $(UBOOT_OUTPUT)/.config

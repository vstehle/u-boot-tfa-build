# SPDX-License-Identifier: GPL-2.0+
#
# Copyright (C) Arm Limited, 2020
#
# Makefile Conventions:
# Variable names:
# TARGET:   U-Boot configuration name; TFA, OP-TEE, and other target
#           configuration names key off the U-Boot configuration; this is a
#           U-Boot oriented tool after all.
# *_PATH:   Full path to project source directories or other assets
# *_OUTPUT: Build directories for each of the sub projects
# *_EXTRA:  Extra parameters to the make call. Gets added to make targets, e.g.
#           "$(MAKE) -C ${PROJECT_PATH} ... ${PROJECT_EXTRA} ..."

ifndef TARGET
  $(error TARGET is not set)
endif

# Set some defaults that can be overridden by the target  makefile include
export DT_PATH    := $(CURDIR)/devicetree-rebasing
export DT_OUTPUT  := $(DT_PATH)
export TFA_PATH   := $(CURDIR)/arm-trusted-firmware
export UBOOT_PATH := $(CURDIR)/u-boot

# Give the option of building in a separate directory
ifdef BUILD_OUTPUT
  __BUILD := $(realpath $(BUILD_OUTPUT))
  export TFA_OUTPUT := $(__BUILD)/tfa
  export TFA_EXTRA += BUILD_BASE=$(TFA_OUTPUT)
  export UBOOT_OUTPUT := $(__BUILD)/u-boot
  export UBOOT_EXTRA += KBUILD_OUTPUT=$(UBOOT_OUTPUT)
else
  export TFA_OUTPUT := $(TFA_PATH)/build
  export UBOOT_OUTPUT := $(UBOOT_PATH)
endif

all: tfa-fip

clean:
	$(MAKE) -C $(UBOOT_PATH) $(UBOOT_EXTRA) mrproper
	cd $(TFA_PATH) && git clean -fdx
	cd $(CURDIR)/mv-ddr && git clean -fdx

$(UBOOT_OUTPUT)/.config:
	mkdir -p $(UBOOT_OUTPUT)
	$(MAKE) -C $(UBOOT_PATH) $(UBOOT_EXTRA) $(TARGET)_defconfig
	echo CONFIG_CMD_BOOTEFI_HELLO=y >> $(UBOOT_OUTPUT)/.config
	echo CONFIG_CMD_BOOTEFI_SELFTEST=y >> $(UBOOT_OUTPUT)/.config
	echo CONFIG_CMD_NVEDIT_EFI=y >> $(UBOOT_OUTPUT)/.config
	echo CONFIG_CMD_EFIDEBUG=y >> $(UBOOT_OUTPUT)/.config
	echo CONFIG_CMD_GPT=y >> $(UBOOT_OUTPUT)/.config
	$(MAKE) -C $(UBOOT_PATH) $(UBOOT_EXTRA) olddefconfig

%: $(UBOOT_OUTPUT)/.config
	$(MAKE) -f scripts/main.mk TARGET=$(TARGET) $@

.PHONY: $(UBOOT_OUTPUT)/.config

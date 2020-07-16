# SPDX-License-Identifier: GPL-2.0+
#
# Copyright (C) Arm Limited, 2020

ifndef TARGET
  $(error TARGET is not set)
endif
MAKE ?= make

# Set some defaults that can be overridden by the target  makefile include
export DT_PATH    := $(CURDIR)/devicetree-rebasing
export TFA_PATH   := $(CURDIR)/arm-trusted-firmware
export UBOOT_PATH := $(CURDIR)/u-boot
export UBOOT_OUTPUT := $(CURDIR)/u-boot/build-$(TARGET)

all: tfa-fip

$(UBOOT_OUTPUT)/.config:
	mkdir -p $(UBOOT_OUTPUT)
	$(MAKE) -C $(UBOOT_PATH) KBUILD_OUTPUT=$(UBOOT_OUTPUT) $(TARGET)_defconfig

%: $(UBOOT_OUTPUT)/.config
	$(MAKE) -f scripts/main.mk TARGET=$(TARGET) $@

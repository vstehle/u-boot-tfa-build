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
export TFA_PATH   := $(CURDIR)/trusted-firmware-a
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

# ===========================================================================
# Rules shared between *config targets and build targets

# To make sure we do not include .config for any of the *config targets
# catch them early
# It is allowed to specify more targets when calling make, including
# mixing *config targets and build targets.
# For example 'make oldconfig all'.
# Detect when mixed targets is specified, and make a second invocation
# of make so .config is not included in this case either (for *config).

no-dot-config-targets := clean

config-targets := 0
mixed-targets  := 0
dot-config     := 1

ifneq ($(filter $(no-dot-config-targets), $(MAKECMDGOALS)),)
	ifeq ($(filter-out $(no-dot-config-targets), $(MAKECMDGOALS)),)
		dot-config := 0
	endif
endif

ifneq ($(filter %config,$(MAKECMDGOALS)),)
        config-targets := 1
        ifneq ($(words $(MAKECMDGOALS)),1)
                mixed-targets := 1
        endif
endif

ifeq ($(mixed-targets),1)
# ===========================================================================
# We're called with mixed targets (*config and build targets).
# Handle them one by one.
PHONY += $(MAKECMDGOALS) __build_one_by_one

$(filter-out __build_one_by_one, $(MAKECMDGOALS)): __build_one_by_one
	@:

__build_one_by_one:
	$(Q)set -e; \
	for i in $(MAKECMDGOALS); do \
		$(MAKE) $$i; \
	done

else
ifeq ($(config-targets),1)
# ===========================================================================
# *config targets only - make sure prerequisites are updated, and descend
# in scripts/kconfig to make the *config target

%config: u-boot/%config
	echo CONFIG_CMD_BOOTEFI_HELLO=y >> $(UBOOT_OUTPUT)/.config
	echo CONFIG_CMD_BOOTEFI_SELFTEST=y >> $(UBOOT_OUTPUT)/.config
	echo CONFIG_CMD_NVEDIT_EFI=y >> $(UBOOT_OUTPUT)/.config
	echo CONFIG_CMD_EFIDEBUG=y >> $(UBOOT_OUTPUT)/.config
	echo CONFIG_CMD_GPT=y >> $(UBOOT_OUTPUT)/.config
	$(MAKE) -C $(UBOOT_PATH) $(UBOOT_EXTRA) olddefconfig

PHONY += defconfig
defconfig: ${TARGET}_defconfig ;

else
# ===========================================================================
# Build targets only
# In general all targets that make use of the selected configuration

ifeq ($(dot-config),1)
# Read in config
-include $(UBOOT_OUTPUT)/.config

# ===================================
# Platform/SOC specific configuration
ifdef CONFIG_ROCKCHIP_RK3399
TFA_PLAT := rk3399
UBOOT_EXTRA += BL31=$(TFA_PATH)/build/$(TFA_PLAT)/release/bl31/bl31.elf
FLASH_IMAGE := $(UBOOT_OUTPUT)/flash_image.bin
DTB_TARGET := src/arm64/$(CONFIG_DEFAULT_FDT_FILE)
u-boot: tfa-bl31

include $(CURDIR)/scripts/rk3399.mk
endif # CONFIG_ROCKCHIP_RK3399

ifdef CONFIG_ARMADA_8K
include scripts/mvebu-armada-8k.mk
DTB_TARGET := src/arm64/marvell/$(CONFIG_DEFAULT_DEVICE_TREE).dtb
ifeq ($(CONFIG_DEFAULT_DEVICE_TREE),"armada-8040-mcbin")
TFA_PLAT := a80x0_mcbin
endif
endif # CONFIG_ARMADA_8K

ifndef TFA_PLAT
  $(warning TFA_PLAT is not set. Either TARGET=$(TARGET) is not yet supported)
  $(error by this tool, or there is a bug)
endif

TFA_EXTRA += PLAT=$(TFA_PLAT)
TFA_EXTRA += LOG_LEVEL=20
TFA_EXTRA += BL33=$(UBOOT_OUTPUT)/u-boot.bin

FLASH_IMAGE ?= $(TFA_OUTPUT)/$(TFA_PLAT)/release/flash-image.bin
FLASH_IMAGE_DEPS ?= tfa/all tfa/fip
SD_IMAGE := $(TARGET)-sdcard.img
ESP_SIZE ?= $$((64*1024*1024))
ESP_OFFSET ?= $$((4*1024*1024))

endif # ifeq ($(dot-config),1)

PHONY += dtb
dtb: ${DTB_TARGET}
	fdtput ${DT_OUTPUT}/${DTB_TARGET} -t s / u-boot-ver `cd ${UBOOT_PATH} && git describe`
	fdtput ${DT_OUTPUT}/${DTB_TARGET} -t s / tfa-ver `cd ${TFA_PATH} && git describe`
	fdtput ${DT_OUTPUT}/${DTB_TARGET} -t s / dt-ver `cd ${DT_PATH} && git describe`

PHONY += flashimage sdimage

flashimage ${FLASH_IMAGE}: ${FLASH_IMAGE_DEPS}

sdimage: flashimage

PHONY += clean
clean: u-boot/mrproper
	cd $(TFA_PATH) && git clean -fdx
	cd $(DT_PATH) && git clean -fdx
	cd $(CURDIR)/mv-ddr && git clean -fdx

endif #ifeq ($(config-targets),1)

# ===========================================================================
# Common targets - Mostly delegates to the individual project build systems

# ================================================
# Delegate to devicetree-rebasing build
devicetree-rebasing/%.dtb:
	${MAKE} -C ${DT_PATH} $*.dtb

# ================================================
# Delegate to trusted-firmware-a build
tfa/%:
	${MAKE} -C ${TFA_PATH} ${TFA_EXTRA} $*

tfa/fip: u-boot/all

# ================================================
# Delegate to u-boot build
u-boot/%:
	$(MAKE) -C $(UBOOT_PATH) $(UBOOT_EXTRA) $*

endif #ifeq ($(mixed-targets),1)


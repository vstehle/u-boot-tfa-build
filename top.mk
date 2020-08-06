# SPDX-License-Identifier: GPL-2.0+
#
# Copyright (C) Arm Limited, 2020
#
# Makefile Conventions:
# Variable names:
# *_PATH:   Full path to project source directories or other assets
# *_OUTPUT: Build directories for each of the sub projects
# *_EXTRA:  Extra parameters to the make call. Gets added to make targets, e.g.
#           "$(MAKE) -C ${PROJECT_PATH} ... ${PROJECT_EXTRA} ..."

# Set some defaults that can be overridden by the target  makefile include
DT_PATH    := $(CURDIR)/devicetree-rebasing
DT_OUTPUT  := $(DT_PATH)
TFA_PATH   := $(CURDIR)/trusted-firmware-a
UBOOT_PATH := $(CURDIR)/u-boot

# Give the option of building in a separate directory
ifdef BUILD_OUTPUT
  __BUILD := $(realpath $(BUILD_OUTPUT))
  TFA_OUTPUT := $(__BUILD)/tfa
  TFA_EXTRA += BUILD_BASE=$(TFA_OUTPUT)
  UBOOT_OUTPUT := $(__BUILD)/u-boot
  UBOOT_EXTRA += KBUILD_OUTPUT=$(UBOOT_OUTPUT)
else
  TFA_OUTPUT := $(TFA_PATH)/build
  UBOOT_OUTPUT := $(UBOOT_PATH)
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
	$(UBOOT_PATH)/scripts/kconfig/merge_config.sh -m -O $(UBOOT_OUTPUT) $(UBOOT_OUTPUT)/.config scripts/ebbr.config
	$(MAKE) -C $(UBOOT_PATH) $(UBOOT_EXTRA) olddefconfig

PHONY += defconfig
defconfig: rockpro64-rk3399_defconfig ;

else
# ===========================================================================
# Build targets only
# In general all targets that make use of the selected configuration

ifeq ($(dot-config),1)
# Read in config
include $(UBOOT_OUTPUT)/.config

# ===================================
# Platform/SOC specific configuration
#
# Try including platform specific configs
# Platform specific config could be SOC, Vendor, or config

-include $(CURDIR)/scripts/cpu-$(subst ",,$(CONFIG_SYS_CPU)).mk
-include $(CURDIR)/scripts/vendor-$(subst ",,$(CONFIG_SYS_VENDOR)).mk
-include $(CURDIR)/scripts/soc-$(subst ",,$(CONFIG_SYS_SOC)).mk
-include $(CURDIR)/scripts/board-$(subst ",,$(CONFIG_SYS_BOARD)).mk
-include $(CURDIR)/scripts/config-$(subst ",,$(CONFIG_SYS_CONFIG_NAME)).mk

ifndef TFA_PLAT
  $(info CONFIG_SYS_VENDOR=$(CONFIG_SYS_VENDOR))
  $(info CONFIG_SYS_SOC=$(CONFIG_SYS_SOC))
  $(info CONFIG_SYS_BOARD=$(CONFIG_SYS_BOARD))
  $(info CONFIG_SYS_CONFIG_NAME=$(CONFIG_SYS_CONFIG_NAME))
  $(warning TFA_PLAT is not set. Either the platform is not yet supported)
  $(error by this tool, or there is a bug)
endif

TFA_EXTRA += PLAT=$(TFA_PLAT)
TFA_EXTRA += LOG_LEVEL=20
TFA_EXTRA += BL33=$(UBOOT_OUTPUT)/u-boot.bin

FLASH_IMAGE ?= $(TFA_OUTPUT)/$(TFA_PLAT)/release/flash-image.bin
FLASH_IMAGE_DEPS ?= tfa/all tfa/fip
SD_IMAGE := $(subst ",,$(CONFIG_SYS_CONFIG_NAME))-sdcard.img
ESP_SIZE ?= $$((64*1024*1024))
ESP_OFFSET ?= $$((4*1024*1024))

endif # ifeq ($(dot-config),1)

ifneq ($(DTB_TARGET),)
PHONY += dtb
dtb: ${DTB_TARGET}
	fdtput ${DT_OUTPUT}/${DTB_TARGET} -t s / u-boot-ver `cd ${UBOOT_PATH} && git describe`
	fdtput ${DT_OUTPUT}/${DTB_TARGET} -t s / tfa-ver `cd ${TFA_PATH} && git describe`
	fdtput ${DT_OUTPUT}/${DTB_TARGET} -t s / dt-ver `cd ${DT_PATH} && git describe`
endif

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


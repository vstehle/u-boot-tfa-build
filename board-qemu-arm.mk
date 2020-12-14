
TFA_PLAT := qemu
OPTEE_PLATFORM := vexpress-qemu_armv8a

UBOOT_EXTRA_CONFIGS += scripts/qemu_arm64_tfa.config
FLASH_IMAGE := nor_flash.bin

OPTEE_EXTRA += CFG_RPMB_FS_DEV_ID=1

ifneq ($(CONFIG_TFABOOT)$(CONFIG_POSITION_INDEPENDENT),yy)
tweakconfig:
	echo "CONFIG_POSITION_INDEPENDENT=y" >> $(UBOOT_OUTPUT)/.config
	echo "CONFIG_TFABOOT=y" >> $(UBOOT_OUTPUT)/.config
	$(MAKE) -C $(UBOOT_PATH) $(UBOOT_EXTRA) olddefconfig

u-boot/all u-boot/u-boot.bin: tweakconfig
endif

all: $(FLASH_IMAGE)
$(FLASH_IMAGE): tfa/all tfa/fip
	dd if=/dev/zero of=$(FLASH_IMAGE) count=$$((64*1024*1024>>9))
	dd if=$(TFA_OUTPUT)/$(TFA_PLAT)/release/bl1.bin of=$(FLASH_IMAGE) bs=4096 conv=notrunc
	dd if=$(TFA_OUTPUT)/$(TFA_PLAT)/release/fip.bin of=$(FLASH_IMAGE) bs=4096 seek=64 conv=notrunc

all: semihosting
semihosting: tfa/all u-boot/all
	mkdir -p output
	cp $(TFA_OUTPUT)/$(TFA_PLAT)/release/*.bin output
ifeq ($(CONFIG_OPTEE),y)
	cp $(OPTEE_OUTPUT)/arm-plat-vexpress/core/tee-header_v2.bin output/bl32.bin
	cp $(OPTEE_OUTPUT)/arm-plat-vexpress/core/tee-pager_v2.bin output/bl32_extra1.bin
	cp $(OPTEE_OUTPUT)/arm-plat-vexpress/core/tee-pageable_v2.bin output/bl32_extra2.bin
endif
	cp $(UBOOT_OUTPUT)/u-boot.bin output/bl33.bin

# Core QEMU configuration.
QEMU_BASE_CONFIG += -machine virt,secure=on -cpu cortex-a57
QEMU_BASE_CONFIG += -smp 2 -m 1024 -d unimp -monitor null -no-acpi
QEMU_BASE_CONFIG += -nographic
QEMU_BASE_CONFIG += -serial stdio  # Non-secure; u-boot console
QEMU_BASE_CONFIG += -serial tcp::5000,server,nowait # Secure; optee
ifneq ($(VIRTDISK),)
QEMU_BASE_CONFIG += -drive if=virtio,format=raw,file=$(VIRTDISK)
endif

qemu-fip:
	qemu-system-aarch64 $(QEMU_BASE_CONFIG) -bios $(FLASH_IMAGE) $(QEMU_EXTRA)

qemu-semihosting:
	cd output && qemu-system-aarch64 $(QEMU_BASE_CONFIG) -bios bl1.bin -semihosting-config enable,target=native $(QEMU_EXTRA)

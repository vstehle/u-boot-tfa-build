
TFA_PLAT := qemu
OPTEE_PLATFORM := vexpress-qemu_armv8a

UBOOT_EXTRA_CONFIGS += scripts/qemu_arm64_tfa.config
FLASH_IMAGE := nor_flash.bin

ifneq ($(CONFIG_TFABOOT)$(CONFIG_POSITION_INDEPENDENT),yy)
tweakconfig:
	echo "CONFIG_POSITION_INDEPENDENT=y" >> $(UBOOT_OUTPUT)/.config
	echo "CONFIG_TFABOOT=y" >> $(UBOOT_OUTPUT)/.config
	$(MAKE) -C $(UBOOT_PATH) $(UBOOT_EXTRA) olddefconfig

u-boot/all u-boot/u-boot.bin: tweakconfig
endif

$(FLASH_IMAGE): tfa/all
	dd if=/dev/zero of=$(FLASH_IMAGE) count=$$((64*1024*1024>>9))
	dd if=$(TFA_OUTPUT)/$(TFA_PLAT)/release/bl1.bin of=$(FLASH_IMAGE) bs=4096 conv=notrunc
	dd if=$(TFA_OUTPUT)/$(TFA_PLAT)/release/fip.bin of=$(FLASH_IMAGE) bs=4096 seek=64 conv=notrunc

qemu: $(FLASH_IMAGE)
	qemu-system-aarch64 -nographic -machine virt,secure=on -cpu cortex-a57 \
		-no-acpi -smp 2 -m 1024 -bios $(FLASH_IMAGE) -d unimp \
		-monitor null -serial stdio -serial tcp::5000,server,nowait


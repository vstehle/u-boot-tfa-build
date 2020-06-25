
DTB_TARGET := src/arm64/rockchip/rk3399-rockpro64-v2.dtb

TFA_PLAT   := rk3399
TFA_EXTRA  := bl31
TFA_DEPS   := dtb

UBOOT_CONFIG := rockpro64-rk3399
UBOOT_EXTRA  := BL31=${TFA_PATH}/build/${TFA_PLAT}/release/bl31/bl31.elf
UBOOT_DEPS   := tfa

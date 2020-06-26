#!/bin/sh
#
# Create partitions for rk3399 firmware on an SD card
#

sudo sgdisk $FLASH_DEV \
	-a 64 -n 1:64:16383  -c 1:idbloader.img -t 1:da438f0d-6932-439e-b9de-ca699da1aede -A 1:=:3 -a 2048 \
	      -n 2:16384:+8M -c 2:u-boot.itb    -t 2:da438f0d-6932-439e-b9de-ca699da1aede -A 2:=:3 \
	      -n 3:0:+512M   -c 3:ESP           -t 3:ef00

sudo gdisk -l $FLASH_DEV

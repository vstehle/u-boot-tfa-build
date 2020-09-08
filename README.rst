.. SPDX-License-Identifier: GPL-2.0+
.. Copyright (C) Arm Limited, 2020

U-Boot w/ Trusted Firmware Image Builder
========================================

This is a simple tool for build Arm firmware images from U-Boot, Trusted
Firmware A, and the Linux devicetree repo.
It uses the git 'repo' tool to clone a copy of each project and a Makefile to
build for various Arm targets.

Using this tool
---------------
It is best to use this tool with the `u-boot-manifest` repo to fetch all the required source repositories.
Use the git `repo` tool to fetch all the projects listed in the manifest and
create the required symlinks.
Install repo first.
Most linux distros have repo packaged.

To initialize the build environment, create a new working directory
and run the repo init command::

  $ mkdir firmware-working
  $ cd firmware-working
  $ repo init -u https://github.com/glikely/u-boot-manifest
  $ repo sync

This will clone all of the required git trees and link the Makefile
into the root directory. To build the firmware, simply type::

  $ make <target_name>_defconfig
  $ make

Where <target_name> is a U-Boot defconfig that can be found in the
u-boot/configs directory.

The QEMU config also provides a ``qemu`` target to run the image::

  $ make qemu

Patches to target projects
--------------------------
There are a few changes to the main projects in the ./patches directory.
You'll may need to apply those to get a working firmware image.

Supported Platforms
-------------------

The following platforms should work out of the box.
More to come as this tool matures.

1. Macchiato-bin ``mvebu_mcbin-88f8040_defconfig``
2. RockPro64 ``rockpro64-rk3399_defconfig``
3. QEMU aarch64 ``qemu_arm64_defconfig``
4. Solidrun LX2k lx2160a-cex7 ``lx2160acex7_tfa_defconfig``
   Need to use git repos listed in ``lx2160a.xml``.
   (see https://github.com/glikely/u-boot-manifest)

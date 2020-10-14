<!--
Title: NXP® i.MX 6UltraLite Evaluation Kit
Category: Board Integrations, Yocto Project
Tags: nxp, yocto, warrior, imx6ul-evk

Author: Daniel Selvan D.
Organisation: Jasmin Infotech Pvt. Ltd

Date: 07.08.2020
Edited on 14.10.2020
-->

This repository contains mender integration files for NXP's i.MX evaluation kits. Currently this supports i.MX 6UL EVK and i.MX 8MM is planned.

Expand the following section to know more.

<details>
<summary>
meta-mender-imx6ul
</summary>

# Board description

The i.MX 6UltraLite processor is the first device in the i.MX product line to have a single Arm® **Cortex®-A7** core operating at speeds of up to **696 MHz**. This EVK enables an LCD display and audio playback as well as many connectivity options.

<!--Replace link without any text while pasting in Mender Hub
https://www.nxp.com/assets/images/en/dev-board-image/MCIMX6UL-EVK-BD.jpg
-->

**Development Board Image:**  
![MCIMX6UL-EVK-BD.jpg](https://www.nxp.com/assets/images/en/dev-board-image/MCIMX6UL-EVK-BD.jpg)

URL: [ i.MX6UltraLite Evaluation Kit - Technical and Functional Specifications](https://www.nxp.com/design/development-boards/i-mx-evaluation-and-development-boards/i-mx6ultralite-evaluation-kit:MCIMX6UL-EVK)

Wiki: [ i.MX 6 series](https://en.wikipedia.org/wiki/I.MX#i.MX_6_series)

# Test results

The Yocto Project releases in the table below have been tested by the Mender community. Please update it if you have tested this integration on other [Yocto Project releases](https://wiki.yoctoproject.org/wiki/Releases?target=_blank):

| Yocto Project | Build                                                                          | Runtime                                                                        |
| ------------- | ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------ |
| warrior (2.7) | <img align="center" alt="test pass" width="28px" src="assets/test_pass.png" /> | <img align="center" alt="test pass" width="28px" src="assets/test_pass.png" /> |

**Build** Means that the Yocto Project build using this Mender integration completes without errors and outputs images.

**Runtime** Means that Mender has been verified to work on the board. For U-Boot-based boards, the [integration checklist](https://docs.mender.io/2.3/devices/yocto-project/bootloader-support/u-boot/integration-checklist#what-is-verified) has been verified.

# Getting started

## Prerequisites

- A supported Linux distribution and dependencies installed on your workstation/laptop as described in the [Yocto Mega Manual](https://www.yoctoproject.org/docs/2.7/mega-manual/mega-manual.html#detailed-supported-distros)

- Google repo tool [installed](https://hub.mender.io/t/google-repo/58/2) and in your `PATH`.

## Configuring the build

### Setup Yocto environment

#### 1. Initialise with custom manifest

Set the Yocto Project branch you are building for:

```bash
# set to your branch, make sure it is supported (see table above)
export BRANCH="warrior"
```

Create a directory for your `mender-imx6ul` setup to live in and clone the
meta information.

```bash
mkdir mender-imx6ul && cd mender-imx6ul
```

Initialise repo manifest:

```bash
repo init -u https://github.com/bgnetworks/meta-mender-community \
          -m meta-mender-imx6ul/scripts/manifest-imx6ul.xml \
          -b ${BRANCH}
```

Fetch layers in manifest:

```bash
repo sync -j $(nproc)
```

#### 2. Manual integration

<details>
<summary>Expand manual integration steps</summary>

- Initialise NXP's i.MX manifest

```bash
repo init -u https://source.codeaurora.org/external/imx/imx-manifest \
          -b imx-linux-warrior -m imx-4.19.35-1.1.0.xml
```

- Fetch manifest layers:

```bash
repo sync -j $(nproc)
```

- Clone `meta-mender-core`

```bash
cd sources/
git clone https://github.com/mendersoftware/meta-mender/tree/warrior -b warrior
```

</details>

## Setup build environment

Initialise the build environment:

1. For first build:

```bash
MACHINE=imx6ulevk DISTRO=fslc-framebuffer source setup-mender-environment imx6ul
```

2. For subsequent builds:

```bash
source setup-mender-environment imx6ul
```

### Configure Mender integration (optional)

<details>
<summary>If you're manually integrating Mender, follow these steps.</summary>

Add `meta-mender-core` to `conf/bblayers.conf`

```bash
bitbake-layers add-layer ../sources/meta-mender/meta-mender-core
```

#### 1. Change U-Boot source

By default `i.MX6 UL` uses Freescale Community BSP and you need to change it to official Freescale U-Boot. The reason is to have a sing U-Boot binary (`.imx`) instead of two binaries (`SPL` & `u-boot`)

```bash
cat >> ../sources/meta-freescale/conf/machine/include/imx-base.inc < EOF
# Now U-Boot will be built as .imx (no seperate SPL and u-boot.img)
IMX_DEFAULT_BOOTLOADER_mx6ul = "u-boot-imx"
EOF
```

Mender behaviour explained [here](https://hub.mender.io/t/mender-not-working-in-imx6-ul/1940/7?u=danie)

#### 2. Change U-Boot binary Name

As the U-Boot source is changed, machine configuration (`imx6ulevk.conf`) has to be updated accordlingly to use the correct output (`u-boot.imx`)

```bash
# Changing U-Boot suffix from img to imx
sed -i '/UBOOT_SUFFIX =/c\UBOOT_SUFFIX = "imx"' ../sources/meta-freescale/conf/machine/imx6ulevk.conf
# Deleting SPL name
sed -i '/SPL_BINARY = "SPL"/d' ../sources/meta-freescale/conf/machine/imx6ulevk.conf
# Updating wks file to use u-boot.imx
sed -i '/WKS_FILE =/c\WKS_FILE = "imx-uboot-bootpart.wks.in"' ../sources/meta-freescale/conf/machine/imx6ulevk.conf
```

By default the U-Boot binary is named `u-boot-dtb.imx` but you need to change it to `u-boot.imx` so as to align with the updated `.wks` file.

Add the following lines to `../sources/poky/meta/recipes-bsp/u-boot/u-boot.inc`

```bash
# Rename u-boot-dtb.imx to u-boot.imx as recognised my mender module for packaging
[ -f ${B}/${config}/u-boot-dtb.imx ] &&
    # If u-boot-dtb.imx presents, create softlink to u-boot.imx
    ln -sf ${B}/${config}/u-boot-dtb.imx ${B}/${config}/u-boot.imx
```

In `conf/local.conf`

```bash
cat >> conf/local.conf < EOF

# This sets the offset where the bootloader should be placed,
# counting from the start of the storage medium
# The offset is specified in units of 512-byte sectors
MENDER_IMAGE_BOOTLOADER_BOOTSECTOR_OFFSET = "2"

# File to be written directly into the boot sector
MENDER_IMAGE_BOOTLOADER_FILE = "u-boot.imx"
EOF
```

#### 3. Adding Mender as a dependency to U-Boot

Now you need to add the mender dependency to U-Boot

```bash
cat >> ../sources/meta-freescale/recipes-bsp/u-boot/u-boot-imx_2018.03.bb < EOF

# Adding mender conf as requirement for U-Boot
require recipes-bsp/u-boot/u-boot-mender.inc

# Package name override
# See https://www.yoctoproject.org/docs/2.7/ref-manual/ref-manual.html
RPROVIDES_${PN} += "u-boot"

# Specific to U-Boot versions prior to v2018.05
SRC_URI_append = " file://0005-fw_env_main.c-Fix-incorrect-size-for-malloc-ed-strin.patch"
EOF

cat >> conf/local.conf < EOF
# See https://docs.mender.io/2.3/artifacts/yocto-project/image-configuration/features
# for details
MENDER_FEATURES_ENABLE_append = " mender-uboot mender-image-sd"
EOF
```

Download the `0005-fw_env_main.c-Fix-incorrect-size-for-malloc-ed-strin.patch` from Mender. [This is a known bug in U-Boot versions prior to v2018.05](https://github.com/mendersoftware/mender-docs/blob/849476a8979d98c620a1bdf9d99168c80a4278a3/201.Troubleshooting/01.Yocto-project-build/docs.md#do_mender_uboot_auto_configure-fails-when-executing-toolsenvfw_printenv--l-fw_printenvlock)

```bash
curl https://raw.githubusercontent.com/mendersoftware/meta-mender/27f9e8dabf461d59dec4d94bd93d6b7207be0040/meta-mender-core/recipes-bsp/u-boot/patches/0005-fw_env_main.c-Fix-incorrect-size-for-malloc-ed-strin.patch?target=_blank  > ../sources/meta-mender/meta-mender-core/recipes-bsp/u-boot/patches/0005-fw_env_main.c-Fix-incorrect-size-for-malloc-ed-strin.patch
```

**Note**: If error occurs in patching `0003-Integration-of-Mender-boot-code-into-U-Boot.patch` modify the patch as follows, (_tested for `u-boot-imx` with `warrior`_)

```bash
cat > ../sources/meta-mender/meta-mender-core/recipes-bsp/u-boot/patches/0003-Integration-of-Mender-boot-code-into-U-Boot.patch < EOF
From 512c08a0ed07c8798d628c5a6420c59ba5188656 Mon Sep 17 00:00:00 2001
From: Marcin Pasinski <marcin.pasinski@northern.tech>
Date: Wed, 31 Jan 2018 18:10:04 +0100
Subject: [PATCH 3/3] Integration of Mender boot code into U-Boot.

Signed-off-by: Kristian Amlie <kristian.amlie@mender.io>
Signed-off-by: Maciej Borzecki <maciej.borzecki@rndity.com>
Signed-off-by: Marcin Pasinski <marcin.pasinski@northern.tech>
---
 include/env_default.h     | 3 +++
 scripts/Makefile.autoconf | 3 ++-
 2 files changed, 5 insertions(+), 1 deletion(-)

diff --git a/include/env_default.h b/include/env_default.h
index 54d8124..9cf272c 100644
--- a/include/env_default.h
+++ b/include/env_default.h
@@ -9,6 +9,7 @@
  */

 #include <env_callback.h>
+#include <env_mender.h>

 #ifdef DEFAULT_ENV_INSTANCE_EMBEDDED
 env_t environment __UBOOT_ENV_SECTION__ = {
@@ -22,6 +23,7 @@
 #else
 const uchar default_environment[] = {
 #endif
+	MENDER_ENV_SETTINGS
 #ifdef	CONFIG_ENV_CALLBACK_LIST_DEFAULT
 	ENV_CALLBACK_VAR "=" CONFIG_ENV_CALLBACK_LIST_DEFAULT "\0"
 #endif
diff --git a/scripts/Makefile.autoconf b/scripts/Makefile.autoconf
index 00b8fb3..e312c80 100644
--- a/scripts/Makefile.autoconf
+++ b/scripts/Makefile.autoconf
@@ -111,7 +111,8 @@
 	echo \#include \<configs/$(CONFIG_SYS_CONFIG_NAME).h\>;		\
 	echo \#include \<asm/config.h\>;				\
 	echo \#include \<linux/kconfig.h\>;				\
-	echo \#include \<config_fallbacks.h\>;)
+	echo \#include \<config_fallbacks.h\>;				\
+	echo \#include \<config_mender.h\>;)
 endef

 include/config.h: scripts/Makefile.autoconf create_symlink FORCE
--
2.7.4

EOF
```

#### 4. Setting kernel address in mender bootcmd

NXP uses `loadaddr` and Mender uses `kernel_addr_r` in `bootcmd` and thus you need to fix it.

```bash
cat >> ../sources/meta-mender/meta-mender-core/recipes-bsp/u-boot/u-boot-mender-common.inc > EOF
# Setting loadaddr as kernel_addr_r
# Mender uses kernel address instead of load address in bootcmd
MENDER_UBOOT_PRE_SETUP_COMMANDS = "setenv kernel_addr_r \${loadaddr}"
EOF
```

REF: [kernel_addr_r](https://hub.mender.io/t/mender-integration-error-no-block-device-in-imx6-ul/1953/10?u=danie) in mender bootcmd

#### 5. Misc configurations

These are specific to `i.MX 6UL` and are required for successful integration.

```bash
cat >> conf/local.conf < EOF
# The name of the image or update that will be built
# This is what the device will report that it is running
# and different updates must have different names
MENDER_ARTIFACT_NAME = "release-1"

# MENDER_FEATURES settings and the inherit of mender-full
INHERIT += "mender-full"

# The storage device holding all partitions
# See https://docs.mender.io/2.3/devices/yocto-project/partition-configuration#configuring-storage
# for more information
MENDER_STORAGE_DEVICE = "/dev/mmcblk1"

# Disabling mender's data grow service
# hat extends the image to fully occupy the SD card
MENDER_FEATURES_DISABLE_append = " mender-growfs-data"

# Disable the UEFI image
MENDER_FEATURES_DISABLE_append = " mender-grub mender-image-uefi"

# Disabling boot partition from mender image
# Mender use rootfs /boot to store and boot kernel & DTBs
MENDER_BOOT_PART_SIZE_MB = "0"
EOF
```

</details>

### Configure Mender server URL (optional)

This section is not required for a successful build but images that are generated by default are only suitable for usage with the Mender client in [Standalone deployments](https://docs.mender.io/2.3/architecture/standalone-deployments), due to lack of server configuration.

You can edit the `conf/local.conf` file to provide your Mender server configuration, ensuring the generated images and Mender Artifacts are connecting to the Mender server that you are using. There should already be a commented section in the generated `conf/local.conf` file and you can simply uncomment the relevant configuration options and assign appropriate values to them.

Build for Hosted Mender:

```bitbake
# To get your tenant token:
# - log in to https://hosted.mender.io
# - click your email at the top right and then "My organization"
# - press the "COPY TO CLIPBOARD"
# - assign content of clipboard to MENDER_TENANT_TOKEN
#
MENDER_SERVER_URL = "https://hosted.mender.io"
MENDER_TENANT_TOKEN = "<copy token here>"
```

Build for Mender demo server:

```bitbake
# https://docs.mender.io/getting-started/create-a-test-environment
#
# Update IP address to match the machine running the Mender demo server
MENDER_DEMO_HOST_IP_ADDRESS = "192.168.0.100"
```

**Note**: If you are facing issues with demo server authentication, change the certificate for Mender server as well as client

See also: [ Replacing keys and certificates](https://docs.mender.io/2.3/administration/certificates-and-keys#replacing-keys-and-certificates)

After changing the certificate, place `server.crt` into the client. You can either place them at `/etc/mender/server.crt` in client or you can follow along to automate it during the build phase.

```bash
export crt_dir=<your_certificates_folder>
mkdir -p ../sources/meta-mender/meta-mender-core/recipes-mender/mender/files
cp crt_dir/server.crt ../sources/meta-mender/meta-mender-core/recipes-mender/mender/files
```

Create or append `../sources/meta-mender/meta-mender-core/recipes-mender/mender/mender_%.bbappend` with following contents.

```bash
cat >> ../sources/meta-mender/meta-mender-core/recipes-mender/mender/mender_%.bbappend < EOF

# Helper function to place the mender connection
# & update certificates on the build.
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI_append = " file://server.crt"
EOF
```

REF: [Mender server authorization error](https://hub.mender.io/t/mender-server-authorization-error-demo-crt-is-missing-in-imx-6ul-evk-yocto-build/1981/4?u=danie)

### Building the image

You can now proceed with building an image:

```bash
bitbake core-image-base
```

Replace `core-image-base` with your desired image target.

### Using the build output

After a successful build, the images and build artifacts are placed in `tmp/deploy/images/imx6ulevk/`.

The disk image (with`.sdimg` suffix) is used to provision the device storage for devices without Mender running already.

**Note**: `.wic.gz` won't contain the [Mender partitions](https://docs.mender.io/2.3/devices/general-system-requirements#partition-layout) and may cause runtime errors. [Ref here](https://hub.mender.io/t/mender-is-not-creating-partitions-in-imx6-ul/1924/3?u=danie)

The files of interest are are,

```bash
$ ls -l *sdimg*
-rw-r--r-- core-image-base-imx6ulevk-20200805132400.sdimg
-rw-r--r-- core-image-base-imx6ulevk-20200805132400.sdimg.bz2
```

Please proceed to [the official documentation on provisioning a new device](https://docs.mender.io/artifacts/provisioning-a-new-device?target=_blank) for steps to do this.

On the other hand, if you already have Mender running on your device and want to deploy a rootfs update using this build, you should use the [Mender Artifact](https://docs.mender.io/2.3/architecture/mender-artifacts) files, which have `.mender` suffix. You can either deploy this Artifact in managed mode with the Mender server as described in [Deploy to physical devices](https://docs.mender.io/2.3/getting-started/on-premise-installation/deploy-a-system-update-demo?target=_blank) or by using the Mender client only in [Standalone deployments](https://docs.mender.io/2.3/architecture/standalone-deployments?target=_blank).

# References

1. The official [Mender documentation](https://docs.mender.io/) explains how Mender works. This is simply a board-specific complement to the official documentation.

2. i.MX Repo Manifest [README](https://source.codeaurora.org/external/imx/imx-manifest/tree/README?h=imx-linux-warrior)

3. meta-mender - [GitHub](https://github.com/mendersoftware/meta-mender/tree/warrior)

4. [Mender not working in i.MX6 UL](https://hub.mender.io/t/mender-not-working-in-imx6-ul/1940)

5. [Mender integration error (No block device) in i.MX6 UL](https://hub.mender.io/t/mender-integration-error-no-block-device-in-imx6-ul/1953)

6. [Kernel signing error after mender integration in i.MX 6UL](https://hub.mender.io/t/kernel-signing-error-after-mender-integration-in-imx-6ul/2002/4?u=danie)

7. [Mender is not creating partitions in i.MX6 UL](https://hub.mender.io/t/mender-is-not-creating-partitions-in-imx6-ul/1924)

8. [Partition grow error on i.MX6 UL EVK](https://hub.mender.io/t/partition-grow-error-on-imx6ul-evk/1902/3)

# Known issues

- Network not starting on boot for `core-image-base` build, to fix refer [Mender Tutorial - How to configure networking using systemd in Yocto Project](https://hub.mender.io/t/how-to-configure-networking-using-systemd-in-yocto-project/1097)
</details>

<details>
<summary>meta-mender-imx8mm</summary>

# TODO:

**Add i.MX 8MM repo and integration doc**

</details>

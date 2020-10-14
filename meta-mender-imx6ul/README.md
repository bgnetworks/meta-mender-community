<!-- File: README.md
     Author: Daniel Selvan, Jasmin Infotech
-->

# meta-mender-imx6ul

This repository is based on [i.MX Linux Yocto Project BSP](https://source.codeaurora.org/external/imx/imx-manifest/tree/?h=imx-linux-warrior) (_4.19.35_1.1.0 release_) and enables [Mender](https://mender.io/) on NXP's [i.MX6UltraLite Evaluation Kit](https://www.nxp.com/design/development-boards/i-mx-evaluation-and-development-boards/i-mx6ultralite-evaluation-kit:MCIMX6UL-EVK).

## Supported board

**NOTE**: This is release is not a production release.

The following board is the only board tested in this release.

- NXP i.MX 6UltraLite EVK (imx6ulevk)

## Quick Start Guide

See the i.MX Yocto Project User's Guide for instructions on installing repo.

1. Install the i.MX Linux BSP & mender repo

```bash
repo init -u https://github.com/bgnetworks/meta-mender-community \
          -m meta-mender-imx6ul/scripts/imx-4.19.35-mender.xml \
          -b warrior
```

2. Download the Yocto Project Layers:

```bash
repo sync
```

If you encounter errors on repo init, remove the `.repo` directory and try `repo init` again.

3. Run i.MX Linux Yocto Project Setup:

```bash
$ [MACHINE=imx6ulevk] [DISTRO=fslc-framebuffer] source setup-mender-environment <build_folder>
```

where

- `<build_folder>` specifies the build folder name

After this your system will be configured to start a Yocto Project build.

## Build images

#### Building Frame Buffer (FB)

```bash
MACHINE=imx6ulevk DISTRO=fslc-framebuffer source setup-mender-environment build-fb
bitbake core-image-base
```

**core-image-base**: "A console-only image that fully supports the target device hardware."

## Contributing

To contribute to the development of this BSP and/or submit patches for new boards please send the patches as bellow:

- meta-mender-community: base build system and metadata  
  Path: sources/meta-mender-community  
  GIT: https://github.com/bgnetworks/meta-mender-community.git

## Maintainer

The author(s) and maintainer(s) of this layer is(are):

- Daniel Selvan D - <daniel.selvan@jasmin-infotech.com> - [danie007](https://github.com/danie007)

Always include the maintainers when suggesting code changes to this layer.

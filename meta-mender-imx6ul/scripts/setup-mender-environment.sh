#!/bin/bash
# -*- mode: bash-script; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*-
#
# Authored-by:  Daniel Selvan (daniel.selvan@jasmin-infotech.com)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# Copyright (C) 2020 Jasmin Infotech.

CWD=$(pwd)
PROGNAME="setup-mender-environment"
PACKAGE_CLASSES=${PACKAGE_CLASSES:-package_rpm}

usage() {
    echo -e "
Usage: MACHINE=<=imx6ulevk> DISTRO=<=fslc-framebuffer> source $PROGNAME <build-dir>
Usage:                                                 source $PROGNAME <build-dir>
    <machine>    machine name (default imx6ulevk)
    <distro>     distro name (default fslc-framebuffer)
    <build-dir>  build directory

The first usage is for creating a new build directory. In this case, the
script creates the build directory <build-dir>, configures it for the
specified <machine> and <distro>, and prepares the calling shell for running
bitbake on the build directory. If no machine or distro is specified it will
defalut to MACHINE=imx6ulevk and DISTRO=fslc-framebuffer

The second usage is for using an existing build directory. In this case,
the script prepares the calling shell for running bitbake on the build
directory <build-dir>. The build directory configuration is unchanged.
"

    ls sources/*/conf/machine/*.conf >/dev/null 2>&1
    ls sources/meta-freescale-distro/conf/distro/fslc-*.conf >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "
Supported machines: $(
            echo
            ls sources/*/conf/machine/*.conf |
                sed s/\.conf//g | sed -r 's/^.+\///' | xargs -I% echo -e "\t%"
        )

Supported Freescale's distros: $(
            echo
            ls sources/meta-freescale-distro/conf/distro/fslc-*.conf |
                sed s/\.conf//g | sed -r 's/^.+\///' | xargs -I% echo -e "\t%"
        )

Available Poky's distros: $(
            echo
            ls sources/poky/meta-poky/conf/distro/*.conf |
                sed s/\.conf//g | sed -r 's/^.+\///' | xargs -I% echo -e "\t%"
        )

Examples:

- To create a new Yocto build directory:
  $ MACHINE=imx6ulevk DISTRO=fslc-framebuffer source $PROGNAME build

- To use an existing Yocto build directory:
  $ source $PROGNAME build
"
    fi
}

clean_up() {
    unset EULA LIST_MACHINES VALID_MACHINE
    unset CWD TEMPLATES SHORTOPTS LONGOPTS ARGS PROGNAME
    unset generated_config updated
    unset MACHINE SDKMACHINE DISTRO OEROOT
}

# get command line options
SHORTOPTS="h"
LONGOPTS="help"

ARGS=$(getopt --options $SHORTOPTS \
    --longoptions $LONGOPTS --name $PROGNAME -- "$@")
# Print the usage menu if invalid options are specified
if [ $? != 0 -o $# -lt 1 ]; then
    usage && clean_up
    return 1
fi

eval set -- "$ARGS"
while true; do
    case $1 in
    -h | --help)
        usage
        clean_up
        return 0
        ;;
    --)
        shift
        break
        ;;
    esac
done

if [ "$(whoami)" = "root" ]; then
    echo "ERROR: do not use the BSP as root. Exiting..."
fi

if [ ! -e $1/conf/local.conf.sample ]; then
    build_dir_setup_enabled="true"
else
    build_dir_setup_enabled="false"
fi

if [ "$build_dir_setup_enabled" = "true" ]; then
    if [ -z "$MACHINE" ]; then
        MACHINE='imx6ulevk'
        echo -e "NOTE: Setting to default machine - i.MX 6UL EVK"

    elif [ "$MACHINE" != "imx6ulevk" ]; then

        # Linking default initialiser
        ln -sf sources/meta-fsl-bsp-release/imx/tools/fsl-setup-release.sh $CWD/fsl-setup-release.sh
        ln -sf sources/base/setup-environment $CWD/setup-environment
        ln -sf sources/base/README $CWD/README-FSL

        echo ""
        echo "$PROGNAME only supports \"imx6ulevk\", for other boards initialise with fsl-setup-release.sh"

        clean_up && return 1
    fi
fi

if [ -z "$SDKMACHINE" ]; then
    SDKMACHINE='i686'
fi

if [ "$build_dir_setup_enabled" = "true" ] && [ -z "$DISTRO" ]; then
    DISTRO='fslc-framebuffer'
    echo -e "NOTE: Setting to default distro - $DISTRO"
fi

OEROOT=$PWD/sources/poky
if [ -e $PWD/sources/oe-core ]; then
    OEROOT=$PWD/sources/oe-core
fi

. $OEROOT/oe-init-build-env $CWD/$1 >/dev/null

# if conf/local.conf not generated, no need to go further
if [ ! -e conf/local.conf ]; then
    clean_up && return 1
fi

# Clean up PATH, because if it includes tokens to current directories somehow,
# wrong binaries can be used instead of the expected ones during task execution
export PATH="$(echo $PATH | sed 's/\(:.\|:\)*:/:/g;s/^.\?://;s/:.\?$//')"

generated_config=
if [ "$build_dir_setup_enabled" = "true" ]; then
    mv conf/local.conf conf/local.conf.sample

    # Generate the local.conf based on the Yocto defaults
    TEMPLATES=$CWD/sources/base/conf
    grep -v '^#\|^$' conf/local.conf.sample >conf/local.conf
    cat >>conf/local.conf <<EOF

DL_DIR ?= "\${BSPDIR}/downloads/"
EOF

    # Appending mender configuration to local.conf
    cat $CWD/sources/meta-mender-community/meta-mender-imx6ul/templates/local.conf.append >>conf/local.conf

    # Change settings according environment
    sed -e "s,MACHINE ??=.*,MACHINE ??= '$MACHINE',g" \
        -e "s,SDKMACHINE ??=.*,SDKMACHINE ??= '$SDKMACHINE',g" \
        -e "s,DISTRO ?=.*,DISTRO ?= '$DISTRO',g" \
        -e "s,PACKAGE_CLASSES ?=.*,PACKAGE_CLASSES ?= '$PACKAGE_CLASSES',g" \
        -i conf/local.conf

    cp $TEMPLATES/* conf/

    for s in $HOME/.oe $HOME/.yocto; do
        if [ -e $s/site.conf ]; then
            echo "Linking $s/site.conf to conf/site.conf"
            ln -s $s/site.conf conf
        fi
    done

    generated_config=1
fi

# Checking repo sync status
[ ! -e "$CWD/sources/meta-freescale/conf/machine/imx6ulevk.conf" ] && {
    echo "ERROR: machine.conf not found"
    echo ""
    echo "Delete this repo and initialise again!"
    # Exit from script
    exit 1
}

# Handle EULA setting
EULA_ACCEPTED=

# EULA has been accepted already (ACCEPT_FSL_EULA is set in local.conf)
if grep -q '^\s*ACCEPT_FSL_EULA\s*=\s*["'\'']..*["'\'']' conf/local.conf; then
    EULA_ACCEPTED=1
fi

if [ -z "$EULA_ACCEPTED" ] && [ -n "$EULA" ]; then
    # The FSL EULA is not set as accepted in local.conf, but the EULA
    # variable is set in the environment, so we just configure
    # ACCEPT_FSL_EULA in local.conf according to $EULA.
    echo "ACCEPT_FSL_EULA = \"$EULA\"" >>conf/local.conf
elif [ -n "$EULA_ACCEPTED" ]; then
    # The FSL EULA has been accepted once, so ACCEPT_FSL_EULA is set
    # in local.conf.  No need to do anything.
    :
else
    # THE FSL EULA is not set as accepted in local.conf, and EULA is
    # not set in the environment, so we need to ask user if he/she
    # accepts the FSL EULA:
    cat <<EOF

Some BSPs depend on libraries and packages which are covered by Freescale's
End User License Agreement (EULA). To have the right to use these binaries in
your images, you need to read and accept the following...

EOF

    sleep 3

    more -d $CWD/sources/meta-freescale/EULA
    echo
    REPLY=
    while [ -z "$REPLY" ]; do
        echo -n "Do you accept the EULA you just read? (y/n) "
        read REPLY
        case "$REPLY" in
        y | Y)
            echo "EULA has been accepted."
            echo "ACCEPT_FSL_EULA = \"1\"" >>conf/local.conf
            EULA=Accepted
            ;;
        *)
            echo "EULA has not been accepted."

            # deleting build directory
            cd $CWD && rm -rf $CWD/$#
            clean_up && return 1
            ;;
        esac
    done
fi

cat <<EOF

Welcome to Freescale Community BSP

The Yocto Project has extensive documentation about OE including a
reference manual which can be found at:
    http://yoctoproject.org/documentation

For more information about OpenEmbedded see their website:
    http://www.openembedded.org/

You can now run 'bitbake <target>'

Common targets are:
    core-image-minimal
    meta-toolchain
    meta-toolchain-sdk
    adt-installer
    meta-ide-support
    core-image-base
    core-image-full-cmdline
    fsl-image-gui

EOF

if [ -n "$generated_config" ]; then

    # Trimming unwanted mender modules
    rm -rf $CWD/sources/meta-mender/meta-mender-commercial $CWD/sources/meta-mender/meta-mender-demo $CWD/sources/meta-mender/meta-mender-qemu $CWD/sources/meta-mender/meta-mender-raspberrypi*

    # Trimming unwanted meta-mender-community layers
    rm -rf $CWD/sources/meta-mender-community/a* $CWD/sources/meta-mender-community/b* $CWD/sources/meta-mender-community/c* $CWD/sources/meta-mender-community/n* $CWD/sources/meta-mender-community/o* $CWD/sources/meta-mender-community/q* $CWD/sources/meta-mender-community/r* $CWD/sources/meta-mender-community/s* $CWD/sources/meta-mender-community/t* $CWD/sources/meta-mender-community/u* $CWD/sources/meta-mender-community/v* $CWD/sources/meta-mender-community/intel

    # Appending build specific layers to bblayers.conf
    cat $CWD/sources/meta-mender-community/meta-mender-imx6ul/templates/bblayers.conf.append >>conf/bblayers.conf

    # Disabling mx6 firmware
    sed -i '/MACHINE_FIRMWARE_append_mx6 =/c\# MACHINE_FIRMWARE_append_mx6 = " linux-firmware-imx-sdma-imx6q"' $CWD/sources/meta-freescale/conf/machine/include/imx-base.inc

    # Updating machine configuration
    cat $CWD/sources/meta-mender-community/meta-mender-imx6ul/templates/imx6ulevk.conf.new >$CWD/sources/meta-freescale/conf/machine/imx6ulevk.conf
    cat <<EOF
Your build environment has been configured with:

    MACHINE=$MACHINE
    SDKMACHINE=$SDKMACHINE
    DISTRO=$DISTRO
    EULA=$EULA
EOF
else
    echo "Your configuration files at $1 have not been touched."
fi

echo "Now you can run 'bitbake core-image-base'"

clean_up

#!/bin/bash

#
#  Build Script for Render Kernel for OPO!
#  Based off AK'sbuild script - Thanks!
#

# Bash Color
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Resources
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
KERNEL="zImage"
DT_IMG="dt.img"
DEFCONFIG="render_defconfig"
CMDLINE="console=ttyHSL0,115200,n8 androidboot.hardware=bacon user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3 androidboot.selinux=permissive"
BASE="0x00000000"
PAGESIZE="2048"
RAMDISK_OFFSET="0x02000000"
TAGS_OFFSET="0x01e00000"

# Kernel Details
VER=Render-Kernel

# Vars
export LOCALVERSION=~`echo $VER`
export CROSS_COMPILE=${HOME}/android/source/toolchains/UBER-arm-eabi-4.9-cortex-a15-05132015/bin/arm-eabi-
export ARCH=arm
export SUBARCH=arm
export KBUILD_BUILD_USER=RenderBroken
export KBUILD_BUILD_HOST=RenderServer.net
export CCACHE=ccache

# Paths
KERNEL_DIR="${HOME}/android/source/kernel/msm8974_OPO_render_kernel"
OZIP_DIR="${HOME}/android/source/kernel/msm8974_OPO_render_kernel/ozip"
MODULES_DIR="${HOME}/android/source/kernel/msm8974_OPO_render_kernel/ozip/system/lib/modules"
RAMDISK_DIR="${HOME}/android/source/kernel/msm8974_OPO_render_kernel_ramdisk"
ZIP_MOVE="${HOME}/android/source/zips/opo-zips"
ZIMAGE_DIR="${HOME}/android/source/kernel/msm8974_OPO_render_kernel/arch/arm/boot"
TOOLS_DIR="${HOME}/android/source/render-tools"
OUT_DIR="${HOME}/android/source/out/opo"
RAMDISK="$OUT_DIR/ramdisk.gz"
VARIANT="OPO"

# Functions
function clean_all {
		rm -rf /home/renderbroken/android/source/kernel/msm8974_OPO_render_kernel/ozip/system/lib/modules/*
		rm -rf $OZIP_DIR/boot.img
		rm -rf arch/arm/boot/"$KERNEL"
		echo
		make clean && make mrproper
}

function make_kernel {
		echo
		make $DEFCONFIG
		make $THREAD
		cp -vr $ZIMAGE_DIR/$KERNEL $OUT_DIR
}

function make_modules {
		rm -rf /home/renderbroken/android/source/kernel/msm8974_OPO_render_kernel/ozip/system/lib/modules/*
		find $KERNEL_DIR -name "*.ko" -exec cp -v {} $MODULES_DIR \;
}

function make_ramdisk {
		$KERNEL_DIR/mkbootfs $RAMDISK_DIR | gzip > $OUT_DIR/ramdisk.gz
}

function make_dt_img {
		$KERNEL_DIR/dtbToolCM -2 -o $OUT_DIR/$DT_IMG -s 2048 -p scripts/dtc/ arch/arm/boot/
}

function make_bootimg {
		$KERNEL_DIR/mkbootimg --kernel $OUT_DIR/zImage --ramdisk $OUT_DIR/ramdisk.gz --cmdline "$CMDLINE" --base $BASE --pagesize $PAGESIZE --offset $RAMDISK_OFFSET --tags-addr $TAGS_OFFSET --dt $OUT_DIR/dt.img -o $OZIP_DIR/boot.img
}

function make_zip {
		cd $OZIP_DIR
		zip -r9 RenderKernel-CM12_"$VARIANT"-R.zip *
		mv RenderKernel-CM12_"$VARIANT"-R.zip $ZIP_MOVE
		cd $KERNEL_DIR
		rm -rf $OUT_DIR/*
}


DATE_START=$(date +"%s")

echo -e "${green}"
echo "Render Kernel Creation Script:"
echo -e "${restore}"

while read -p "Do you want a clean build (y/n)? " cchoice
do
case "$cchoice" in
	y|Y )
		clean_all
		echo
		echo "All Cleaned now."
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

echo

while read -p "Do you want to build kernel (y/n)? " dchoice
do
case "$dchoice" in
	y|Y)
		make_kernel
		make_modules
		make_ramdisk
		make_dt_img
		make_bootimg
		make_zip
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

echo -e "${green}"
echo "Build Completed in:"
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."

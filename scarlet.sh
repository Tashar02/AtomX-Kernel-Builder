#!/usr/bin/env bash
# Copyright (c) 2021-2022, Tashfin Shakeer Rhythm <tashfinshakeerrhythm@gmail.com>.
# Revision: 11-02-2023 V7.2

# Colors
R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
W='\033[1;37m'

# User infomation
USER='Tashar'
HOST='Cirrus'
BOT_MSG_URL="https://api.telegram.org/bot$BOT_API_KEY/sendMessage"
BOT_BUILD_URL="https://api.telegram.org/bot$BOT_API_KEY/sendDocument"
COMPILER="$1"

# Script configuration
BUILD='clean'

# Device configuration
NAME='Mi A2 / 6X'
DEVICE='wayne'
DEVICE2='jasmine'
CAM_LIB='3'
HAPTICS='2'
PARTITION='DYNAMIC'

# Paths
KERNEL_DIR="$HOME/kernel"
TOOLCHAIN="$HOME/clang"
ZIP_DIR="$HOME/AnyKernel3"
AKSH="$ZIP_DIR/anykernel.sh"
cd $KERNEL_DIR

# Defconfig & Camera library selection

case $CAM_LIB in
1)
	DFCF="vendor/${DEVICE}-perf_defconfig"
	CAM=NEWCAM
	;;
2)
	DFCF="vendor/${DEVICE}-old-perf_defconfig"
	CAM=OLDCAM
	;;
3)
	DFCF="vendor/${DEVICE}-oss-perf_defconfig"
	CAM=OSSCAM
	;;
esac

# Haptics driver selection
case $HAPTICS in
1)
	HAPTIC=QPNP
	;;
2)
	HAPTIC=QTI
	;;
esac

# LTO variant selection
if [[ "$CONFIG_LTO_CLANG_THIN" != "y" ] && "$CONFIG_LTO_CLANG_FULL" == "y" ]]; then
	VARIANT='FULL_LTO'
elif [[ "$CONFIG_LTO_CLANG_THIN" == "y" && "$CONFIG_LTO_CLANG_FULL" == "y" ]]; then
	VARIANT='THIN_LTO'
else
	VARIANT='NON_LTO'
fi

# Functions to send messages/files to telegram
tg_post_msg() {
	curl -s -X POST "$BOT_MSG_URL" -d chat_id="$CHAT_ID" \
		-d "disable_web_page_preview=true" \
		-d "parse_mode=html" \
		-d text="$1"
}

tg_post_build() {
	#Post MD5Checksum alongwith for easeness
	MD5CHECK=$(md5sum "$1" | cut -d' ' -f1)

	#Show the Checksum alongwith caption
	curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
		-F chat_id="$CHAT_ID" \
		-F "disable_web_page_preview=true" \
		-F "parse_mode=html" \
		-F caption="$2 | <b>MD5 Checksum : </b><code>$MD5CHECK</code>"
}

# Function to print error message
error() {
	echo -e ""
	echo -e "$R Error! $Y$1"
	echo -e ""
	exit 1
}

# Flags to be passed to compile
flags() {
	if [[ "$COMPILER" == "clang" ]]; then
		CC='clang'
		HOSTCC="$CC"
		HOSTCXX="$CC++"
		CC_64='aarch64-linux-gnu-'
		C_PATH="$TOOLCHAIN/clang"
		sed -i '/CONFIG_SOUND_CONTROL=y/ a CONFIG_LTO_CLANG_FULL=y' $CONFIG
	elif [[ "$COMPILER" == "gcc" ]]; then
		HOSTCC='gcc'
		CC_64='aarch64-elf-'
		CC='aarch64-elf-gcc'
		HOSTCXX='aarch64-elf-g++'
		C_PATH="$TOOLCHAIN/gcc64/bin:$TOOLCHAIN/gcc32"
	else
		clear
		error 'Value not recognized'
	fi
	CC_32="$TOOLCHAIN/gcc32/bin/arm-eabi-"
	CC_COMPAT="$TOOLCHAIN/gcc32/bin/arm-eabi-gcc"
	env
}
export PATH=$C_PATH/bin:$PATH

# Function to pass compilation flags
pass() {
	make O=work $CFLAG ARCH=arm64 \
		CC=$CC \
		LLVM=1 \
		LLVM_IAS=1 \
		PYTHON=python3 \
		KBUILD_BUILD_USER=$USER \
		KBUILD_BUILD_HOST=$HOST \
		AS=llvm-as \
		AR=llvm-ar \
		NM=llvm-nm \
		LD=ld.lld \
		STRIP=llvm-strip \
		OBJCOPY=llvm-objcopy \
		OBJDUMP=llvm-objdump \
		OBJSIZE=llvm-objsize \
		HOSTLD=ld.lld \
		HOSTCC=$HOSTCC \
		HOSTCXX=$HOSTCXX \
		HOSTAR=llvm-ar \
		PATH=$C_PATH/bin:$PATH \
		CROSS_COMPILE=$CC_64 \
		CC_COMPAT=$CC_COMPAT \
		CROSS_COMPILE_COMPAT=$CC_32 \
		LD_LIBRARY_PATH=$C_PATH/lib:$LD_LIBRARY_PATH \
		2>&1 | tee log.txt
}

# Cleanup the build environment
env() {
	clear
	if [[ "$BUILD" == "clean" ]]; then
		rm -rf work log.txt || mkdir work
	else
		make O=work clean mrproper distclean
	fi
	compile
}

# Let the compilation begin
compile() {
	CFLAG=$DFCF
	pass

	echo -e "$B"
	echo -e "                Build started                "
	echo -e "$G"

	BUILD_START=$(date +"%s")

	CFLAG=-j$(nproc --all)
	pass

	# Compilation ends
	BUILD_END=$(date +"%s")

	echo -e "$B"
	echo -e "                Zipping started                "
	echo -e "$W"
	check
}

# Check for AnyKernel3
check() {
	if [[ -f $KERNEL_DIR/work/arch/arm64/boot/Image.gz-dtb ]]; then
		if [[ -d $ZIP_DIR ]]; then
			zip_ak
		else
			error 'Anykernel is not present, cannot zip'
		fi
	else
		tg_post_build "log.txt" "Build failed!!"
		error 'Kernel image not found!!'
	fi
}

# Pack the image-gz.dtb using AnyKernel3
zip_ak() {
	source work/.config

	FDEVICE=${DEVICE^^}
	FDEVICE2=${DEVICE2^^}
	KNAME=$(echo "$CONFIG_LOCALVERSION" | cut -c 2-)

	cp $KERNEL_DIR/work/arch/arm64/boot/Image.gz-dtb $ZIP_DIR/

# Post the log after a successful build
	tg_post_build "log.txt" "Compiled kernel successfully!!"

	cd $ZIP_DIR

	FINAL_ZIP="$KNAME-$CAM-$HAPTIC-$PARTITION-$FDEVICE2-$FDEVICE-$(date +"%H%M")"
	zip -r9 "$FINAL_ZIP".zip * -x README.md LICENSE FUNDING.yml *placeholder zipsigner*
	java -jar zipsigner* "$FINAL_ZIP.zip" "$FINAL_ZIP-signed.zip"
	FINAL_ZIP="$FINAL_ZIP-signed.zip"

# Post the kernel zip
	tg_post_build "$FINAL_ZIP" "${CAM}+${HAPTIC}"

	cd $KERNEL_DIR

	DIFF=$(($BUILD_END - $BUILD_START))
	KV=$(cat $KERNEL_DIR/work/include/generated/utsrelease.h | cut -c 21- | tr -d '"')
	COMMIT_NAME=$(git show -s --format=%s)
	COMMIT_HASH=$(git rev-parse --short HEAD)

# Print the build information
	tg_post_msg "
	=========Scarlet-X Kernel=========
	Compiler: <code>$CONFIG_CC_VERSION_TEXT</code>
	Linux Version: <code>$KV</code>
	Maintainer: <code>$USER</code>
	Device: <code>$NAME</code>
	Codename: <code>$DEVICE</code>
	Zipname: <code>$FINAL_ZIP</code>
	Variant: <code>$VARIANT, $PARTITION</code>
	Build Date: <code>$(date +"%Y-%m-%d %H:%M")</code>
	Build Duration: <code>$(($DIFF / 60)).$(($DIFF % 60)) mins</code>
	Last Commit Name: <code>$COMMIT_NAME</code>
	Last Commit Hash: <code>$COMMIT_HASH</code>
	"
	exit 0
}
flags

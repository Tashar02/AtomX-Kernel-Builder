# SPDX-License-Identifier: GPL-3.0
# Copyright © 2021,
# Author(s): Divyanshu-Modi <divyan.m05@gmail.com>, Tashfin Shakeer Rhythm <tashfinshakeerrhythm@gmail.com>
# Revision: 01-10-2021 V1

	VERSION='6.1'
	COMPILER="$1"

# USER
	USER='Tashar'
	HOST='Alpha-α'

# DEVICE CONFIG
	DEVICENAME='Mi A2 / Mi 6X'
	DEVICE='wayne'
	DEVICE2=''
	CAM_LIB=''

# PATH
	KERNEL_DIR="$HOME/Kernel"
	ZIP_DIR="$HOME/Repack"
	AKSH="$ZIP_DIR/anykernel.sh"

# DEFCONFIG
	DFCF="${DEVICE}_defconfig"
	if [[ ! -f $KERNEL_DIR/arch/arm64/configs/$DFCF ]]; then
		DFCF="${DEVICE}-perf_defconfig"
		if [[ ! -f $KERNEL_DIR/arch/arm64/configs/$DFCF ]]; then
			DFCF="vendor/${DEVICE}_defconfig"
			if [[ ! -f $KERNEL_DIR/arch/arm64/configs/$DFCF ]]; then
				DFCF="vendor/${DEVICE}-perf_defconfig"
        		fi
        	fi
	fi
	CONFIG="$KERNEL_DIR/arch/arm64/configs/$DFCF"

# Set variables
	if [[ "$COMPILER" == "CLANG" ]]; then
		CC='clang'
		HOSTCC="$CC"
		HOSTCXX="$CC++"
		C_PATH="$HOME/clang"
		CC_64='aarch64-linux-gnu-'
		CC_COMPAT='arm-linux-gnueabi-'
	elif [[ "$COMPILER" == "GCC" ]]; then
		HOSTCC='gcc'
		CC_64='aarch64-elf-'
		CC='aarch64-elf-gcc'
		C_PATH="$HOME/gcc-arm64"
		HOSTCXX='aarch64-elf-g++'
		CC_COMPAT="$HOME/gcc-arm32/bin/arm-eabi-"
	fi

	muke() {
		make O=$COMPILER $CFLAG ARCH=arm64     \
		    	$FLAG                          \
			CC=$CC                         \
			LLVM=1                         \
			LLVM_IAS=1                     \
			HOSTCC=$HOSTCC                 \
			HOSTCXX=$HOSTCXX               \
			CROSS_COMPILE=$CC_64           \
			PATH=$C_PATH/bin:$PATH         \
			KBUILD_BUILD_USER=$USER        \
			KBUILD_BUILD_HOST=$HOST        \
			CROSS_COMPILE_ARM32=$CC_COMPAT \
			CROSS_COMPILE_COMPAT=$CC_COMPAT\
			LD_LIBRARY_PATH=$C_PATH/lib:$LD_LIBRARY_PATH
	}

	CFLAG=$DFCF
	muke

	source $COMPILER/.config
	if [[ "$CONFIG_LTO_CLANG_THIN" != "y" && "$CONFIG_LTO_CLANG_FULL" == "y" ]]; then
		VARIANT='FULL_LTO'
	elif [[ "$CONFIG_LTO_CLANG_THIN" == "y" && "$CONFIG_LTO_CLANG_FULL" == "y" ]]; then
		VARIANT='THIN_LTO'
	else
		VARIANT='NON_LTO'
	fi
	telegram-send --format html "Building: <code>$VARIANT</code>"

	BUILD_START=$(date +"%s")

	CFLAG=-j$(nproc)
	muke

	BUILD_END=$(date +"%s")

	if [[ -f $KERNEL_DIR/$COMPILER/arch/arm64/boot/Image.gz-dtb ]]; then
		FDEVICE=${DEVICE^^}
		KNAME=$(echo "$CONFIG_LOCALVERSION" | cut -c 2-)
		
		if [[ "$CAM_LIB" == "" ]]; then
			CAM=NEW-CAM
		else
			CAM=OLD-LIB
		fi
		
		cp $KERNEL_DIR/$COMPILER/arch/arm64/boot/Image.gz-dtb $ZIP_DIR/

		sed -i "s/demo1/$DEVICE/g" $AKSH
		if [[ "$DEVICE2" ]]; then
			sed -i "/device.name1/ a device.name2=$DEVICE2" $AKSH
		fi

		cd $ZIP_DIR

		FINAL_ZIP="$KNAME-$CAM-$FDEVICE-$VARIANT-`date +"%H%M"`"
		zip -r9 "$FINAL_ZIP".zip * -x README.md *placeholder zipsigner*
		java -jar zipsigner* "$FINAL_ZIP.zip" "$FINAL_ZIP-signed.zip"
		FINAL_ZIP="$FINAL_ZIP-signed.zip"

		telegram-send --file $ZIP_DIR/$FINAL_ZIP

		rm *.zip Image.gz-dtb

		cd $KERNEL_DIR

		sed -i "s/$DEVICE/demo1/g" $AKSH
		if [[ "$DEVICE2" ]]; then
			sed -i "/device.name2/d" $AKSH
		fi

		DIFF=$(($BUILD_END - $BUILD_START))
		COMPILER_NAME="$($C_PATH/bin/$CC --version 2>/dev/null | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"

		telegram-send --disable-web-page-preview --format html "\
		========Scarlet Kernel========
		Compiler: <code>$COMPILER</code>
		Compiler-name: <code>$COMPILER_NAME</code>
		Linux Version: <code>$(make kernelversion)</code>
		Builder Version: <code>$VERSION</code>
		Build Type: <code>$VARIANT</code>
		Maintainer: <code>$USER</code>
		Device: <code>$DEVICENAME</code>
		Codename: <code>$DEVICE</code>
		Camlib: <code>$CAM</code>
		Build Date: <code>$(date +"%Y-%m-%d %H:%M")</code>
		Build Duration: <code>$(($DIFF / 60)).$(($DIFF % 60)) mins</code>
		Changelog: <a href='$SOURCE'> Here </a>
		Last Commit Name: <code>$(git show -s --format=%s)</code>
		Last Commit Hash: <code>$(git rev-parse --short HEAD)</code>"
	else
		telegram-send "Error⚠️ $COMPILER failed to build"
		exit 1
	fi

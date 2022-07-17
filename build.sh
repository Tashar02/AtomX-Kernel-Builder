#!/bin/bash
set -e

cd "$KERNEL_DIR"
mkdir out
export PATH=$KERNEL_DIR/clang/bin:$PATH

USER='Tashar'
HOST='Endeavour'
DEVICENAME='Mi A2 / Mi 6X'
DEVICE='wayne'
CAM=NEW-CAM
KNAME="ScarletX"
KERNEL_DIR="$BUILDDIR/Kernel"
ZIP_DIR="$BUILDDIR/Repack"
AKSH="$ZIP_DIR/anykernel.sh"
VARIANT='FULL_LTO'

DFCF="vendor/${DEVICE}-oss-perf_defconfig"
CONFIG="$KERNEL_DIR/arch/arm64/configs/vendor/${DEVICE}-oss-perf_defconfig"

echo "CONFIG_LTO_CLANG_THIN=y" >>$CONFIG

echo "Building The Kramel"
make O=out $DFCF \
	LLVM=1 \
	LLVM_IAS=1 \
	ARCH=arm64 \
	CC=clang \
	LD=ld.lld \
	AR=llvm-ar \
	NM=llvm-nm \
	STRIP=llvm-strip \
	OBJCOPY=llvm-objcopy \
	OBJDUMP=llvm-objdump \
	OBJSIZE=llvm-size \
	HOSTCC=clang \
	HOSTCXX=clang++ \
	HOSTAR=llvm-ar \
	HOSTLD=ld.lld \
	CROSS_COMPILE=aarch64-linux-gnu- \
	CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
	LD_LIBRARY_PATH=$KERNEL_DIR/clang/lib:$LD_LIBRARY_PATH

telegram-send --format html "Building: <code>$VARIANT</code>"

BUILD_START=$(date +"%s")
make -j$(nproc --all) O=out \
	LLVM=1 \
	LLVM_IAS=1 \
	ARCH=arm64 \
	CC=clang \
	LD=ld.lld \
	AR=llvm-ar \
	NM=llvm-nm \
	STRIP=llvm-strip \
	OBJCOPY=llvm-objcopy \
	OBJDUMP=llvm-objdump \
	OBJSIZE=llvm-size \
	HOSTCC=clang \
	HOSTCXX=clang++ \
	HOSTAR=llvm-ar \
	HOSTLD=ld.lld \
	CROSS_COMPILE=aarch64-linux-gnu- \
	CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
	LD_LIBRARY_PATH=$KERNEL_DIR/clang/lib:$LD_LIBRARY_PATH

cp $KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb $ZIP_DIR/

sed -i "s/demo1/$DEVICE/g" $AKSH

BUILD_END=$(date +"%s")
DIFF=$((BUILD_END - BUILD_START))

cd $ZIP_DIR

FINAL_ZIP="$KNAME-$CAM-$DEVICE-$VARIANT-$(date +"%H%M")"
zip -r9 "$FINAL_ZIP".zip * -x README.md LICENSE FUNDING.yml *placeholder zipsigner*
java -jar zipsigner* "$FINAL_ZIP.zip" "$FINAL_ZIP-signed.zip"
FINAL_ZIP="$FINAL_ZIP-signed.zip"

telegram-send --file $ZIP_DIR/$FINAL_ZIP

telegram-send "Time: $((DIFF / 60)).$((DIFF % 60)) mins"

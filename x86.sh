#!/bin/bash
set -e

cd "$KERNEL_DIR"
export PATH=$KERNEL_DIR/clang/bin:$PATH

echo "Building x86"
make distclean defconfig \
	LLVM=1 \
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
	HOSTLD=ld.lld

make all -j$(nproc --all) \
	LLVM=1 \
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
	HOSTLD=ld.lld || exit ${?}

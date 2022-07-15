#!/bin/bash
set -e

export LINUX_VER=5.18.11
export BUILDDIR=$(pwd)
export KERNEL_DIR="$BUILDDIR/linux-$LINUX_VER"

if [ -d "$KERNEL_DIR"/ ]; then
	echo "Kernel dir found"
else
	wget "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-$LINUX_VER.tar.xz"
	tar xvf linux-$LINUX_VER.tar.xz
fi

if [ -d "$KERNEL_DIR/clang"/ ]; then
	echo "clang dir found"
else
	cd "$KERNEL_DIR"
	git clone https://gitlab.com/dakkshesh07/neutron-clang.git --depth=1 clang
fi

cd "$BUILDDIR"
if [[ $1 == "X86" ]]; then
	bash x86.sh
elif [[ $1 == "ARM64" ]]; then
	bash arm64.sh
elif [[ $1 == "ARM" ]]; then
	bash arm.sh
fi
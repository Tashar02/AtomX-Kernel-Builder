#!/usr/bin/env bash

# Helper function for cloning: gsc = git shallow clone
gsc() {
	git clone --depth=1 -q $@
}

# Clone GCC
gsc https://github.com/mvaisakh/gcc-arm64 -b gcc-master $HOME/gcc-arm64
gsc https://github.com/mvaisakh/gcc-arm -b gcc-master $HOME/gcc-arm32

# Clone CLANG
mkdir $HOME/clang && cd $HOME/clang
bash <(curl -s https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman) -S
cd ..

# Clone AnyKernel3
gsc https://github.com/Tashar02/AnyKernel3.git $HOME/AnyKernel3

# Clone Kernel Source
gsc https://github.com/Atom-X-Devs/android_kernel_xiaomi_scarlet.git -b test $HOME/kernel

# Setup Scripts
mv scarlet.sh $HOME/kernel/scarlet.sh
cd $HOME/kernel

# Compile the kernel using CLANG
bash scarlet.sh clang

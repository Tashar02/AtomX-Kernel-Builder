#!/bin/bash
set -e

export BUILDDIR=$(pwd)
export KERNEL_DIR="$BUILDDIR/Kernel"

git clone --depth=1 https://github.com/Atom-X-Devs/android_kernel_xiaomi_scarlet.git -b default-QTI $BUILDDIR/Kernel
git clone --depth=1 https://gitlab.com/dakkshesh07/neutron-clang.git -b experimental $KERNEL_DIR/clang
git clone --depth=1 https://github.com/Tashar02/AnyKernel3.git $BUILDDIR/Repack

mkdir $HOME/.config
mv telegram-send.conf $HOME/.config/telegram-send.conf
sed -i s/demo1/${BOT_API_KEY}/g $HOME/.config/telegram-send.conf
sed -i s/demo2/${CHAT_ID}/g $HOME/.config/telegram-send.conf

cd "$BUILDDIR"
bash build.sh

#!/bin/bash

#	git clone --depth=1 https://github.com/KenHV/gcc-arm64 -b master $HOME/gcc-arm64
#	git clone --depth=1 https://github.com/KenHV/gcc-arm -b master $HOME/gcc-arm32
	git clone --depth=1 https://gitlab.com/dakkshesh07/neutron-clang.git -b Neutron-15 $HOME/clang
	git clone --depth=1 https://github.com/Tashar02/AnyKernel3.git $HOME/Repack
	git clone --depth=1 https://github.com/Atom-X-Devs/android_kernel_xiaomi_scarlet.git -b default-QTI $HOME/Kernel

	pip3 install telegram-send

	mkdir $HOME/.config
	mv telegram-send.conf $HOME/.config/telegram-send.conf
	sed -i s/demo1/${BOT_API_KEY}/g $HOME/.config/telegram-send.conf
	sed -i s/demo2/${CHAT_ID}/g $HOME/.config/telegram-send.conf
	mv build.sh $HOME/Kernel/build.sh

	cd $HOME/Kernel
	bash build.sh CLANG
#	bash build.sh GCC

	exit

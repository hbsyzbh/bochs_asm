#!/bin/sh

echo "Creating disk.img..."
#bximage -mode=create -hd=10M -q disk.img
rm disk.img
bximage -hd -mode=flat -size=10M -q disk.img

echo "Compiling..."
nasm -I include/ -o mbr.bin mbr.asm || exit
nasm -I include/ -o loader.bin loader.asm || exit

echo "Writing mbr and loader to disk..."
dd if=mbr.bin of=disk.img bs=512 count=1 conv=notrunc
dd if=loader.bin of=disk.img bs=512 count=242 seek=2 conv=notrunc

echo "Now start bochs and have fun!"
bochs -f bochsrc -rc debug.rc

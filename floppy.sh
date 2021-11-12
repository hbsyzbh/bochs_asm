#!/bin/sh

echo "Creating disk.img..."
#bximage -mode=create -hd=10M -q disk.img
rm floppy.img
bximage -fd -size=1.44 -q floppy.img

echo "Compiling..."
nasm -I include/ -o floppy.bin floppy.asm || exit
nasm -I include/ -o loader.bin loader.asm || exit

echo "Writing mbr and loader to disk..."
dd if=floppy.bin of=floppy.img bs=512 count=1 conv=notrunc
dd if=loader.bin of=floppy.img bs=512 count=242 seek=2 conv=notrunc

echo "Now start bochs and have fun!"
bochs -f bochsrc.floppy -rc debug.rc

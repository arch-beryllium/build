#!/bin/bash
if [ "$#" -ne 1 ]; then
  echo "Usage: qemu.sh <image name>"
  echo "Image names: phosh, plasma-mobile"
  exit 1
fi

if [ "$(id -u)" -ne "0" ]; then
  echo "This script requires root."
  exit 1
fi

set -ex

if [ ! -f "build/qemu-$1.cow" ]; then
  qemu-img create -o "backing_file=rootfs-$1.img,backing_fmt=raw" -f qcow2 "build/qemu-$1.cow"
fi

qemu-system-aarch64 \
  -nodefaults \
  -kernel build/sdm845-linux/arch/arm64/boot/Image \
  -initrd build/initramfs.img \
  -append "root=/dev/vda1 rw audit=0" \
  -smp "$(nproc --all)" \
  -m 6G \
  -serial stdio \
  -drive "file=build/qemu-$1.cow,format=qcow2,if=virtio" \
  -device virtio-mouse-pci \
  -device virtio-keyboard-pci \
  -nic user,model=virtio-net-pci \
  -M virt \
  -cpu cortex-a57 \
  -device virtio-gpu-pci \
  -display sdl,gl=on,show-cursor=on \
  -vga virtio

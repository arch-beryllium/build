#!/bin/bash
if [ "$#" -ne 1 ]; then
  echo "Usage: qemu.sh <image name>"
  echo "Image names: barebone, phosh, plasma-mobile, lomiri"
  exit 1
fi

if [ "$(id -u)" -ne "0" ]; then
  echo "This script requires root."
  exit 1
fi

set -ex

if [ ! -f "build/$1-qemu.cow" ]; then
  # Don't use minimal image because it has less disk space
  qemu-img create -o "backing_file=$1-rootfs.img,backing_fmt=raw" -f qcow2 "build/$1-qemu.cow"
fi

qemu-system-aarch64 \
  -nodefaults \
  -kernel "build/$1-Image" \
  -initrd "build/$1-initramfs.img" \
  -append "root=/dev/vda1 rw audit=0 bootsplash.bootfile=bootsplash" \
  -smp "$(nproc --all)" \
  -m 6G \
  -serial stdio \
  -drive "file=build/$1-qemu.cow,format=qcow2,if=virtio" \
  -device virtio-mouse-pci \
  -device virtio-keyboard-pci \
  -nic user,model=virtio-net-pci \
  -M virt \
  -cpu cortex-a57 \
  -device virtio-gpu-pci \
  -display sdl,gl=on,show-cursor=on

# Arch Linux on beryllium (Xiaomi Poco F1)

Run Arch Linux natively on your Poco F1 without [Halium](https://halium.org).

# Community

As more people are trying Arch Linux ARM on Poco F1, I see the need for a group to exchange and bug reports and help in
general. The group can be reached under the bridged rooms https://matrix.to/#/#arch-beryllium:matrix.org
and https://t.me/arch_beryllium.

# Config

Available image names are: `barebone`, `phosh`, `plasma-mobile`, `lomiri`  
Available panel types are: `tianma`, `ebbg`  
Please use those values for `<image name>` and `<panel type>`

# Building

To speed up package downloads you can use the `LOCAL_MIRROR` environment variable with and value
like `http://192.168.178.30:8080/\$repo/\$arch` with https://github.com/arch-beryllium/mirror as local mirror tool.  
(If you have used `arch-repo-mirror` previously for mirroring there is a quick migration guide available in the new
repo).  
Without it, you will probably wait for hours on every build, so it's highly recommended.

```bash
./build.sh <image name>
```

## Copying the rootfs to a bootable location

### Flashing onto SD card

You need at least an 8 GB SD card, but more is better.  
Everything on the SD card will be deleted so watch out what you are doing.

```bash
./flash_sdcard.sh <image name> /dev/sdX
```

### Using Jumpdrive

Download `boot-xiaomi-beryllium-<panel type>.img` from https://github.com/dreemurrs-embedded/Jumpdrive/releases/latest.
Go to bootloader mode and boot it using `fastboot boot boot-xiaomi-beryllium-<panel type>.img`.  
When it booted you should see a splashscreen and some USB mass storage device exposed to your computer. If you have an
SD card inserted it should also be exposed, but make sure to not chose it.  
Find the device using `fdisk -l` (should show up as 53.51 GiB disk).

```bash
./push_jumpdrive.sh <image name> /dev/sdX
```

### Using TWRP

_It's better to use the installer method._  
This will not overwrite anything (except an old rootfs image maybe).

```bash
./push_twrp.sh <image name>
```

### Creating an TWRP zip installer

This basically does the same as pushing the rootfs on the userdata partition and flashing the boot partition, but in a
much more user-friendly way.  
When using this installer the boot partition gets flashed automatically, so be aware of this. It also means you can skip
flashing the boot partition manually and directly boot it.

```bash
./make_installer.sh <image name> <panel type>
adb push build/<image name>-installer-<panel type>.zip /sdcard
```

In TWRP just install the zip as usual (You can also
use `adb shell twrp install /sdcard/<image name>-installer-<panel type>.zip`)

# Booting

Boot the device to bootloader mode (you might need to reboot it once to bootloader mode if you put the SD card into the
device after it already booted to bootloader mode).

To temporarily boot use:

```bash
./boot.sh <image name> <panel type>
```

To permanently boot use:

```bash
./flash_boot.sh <image name> <panel type>
```

On the first boot it will take a longer time, because it resizes the rootfs to the full size. Please don't turn it off
in that time.

# SSHing into the device

Run this script to ssh into the device:

```bash
./ssh.sh
```

The default password is `123456`.

# Enable USB internet forwarding

This will block Wi-Fi on the device until rebooting.  
Host side:

```bash
./enable_forwarding.sh
```

Device side:

```bash
sudo route add default gw 10.15.19.100
```

# USB file transfer

This exposes `/` and any SD card that is not mounted at `/` to other devices as mass storage.  
To enable run `sudo usb-file-transfer`.

# Default apps

Usually only a terminal app and a software store will be installed by default. To install a set of default apps
install `apps-<image name>-meta` manually.

# QEMU

You can also run the image in QEMU:

```bash
./qemu.sh <image name>
```

It uses a qcow2 overlay image, so the rootfs won't be changed.  
It also automatically forwards network requests, and you don't need to use ssh to get a shell, because script
automatically opens a console for you.

# Kernel updates

## Device

When you flash the boot.img permanently, every kernel update on the device will flash the new boot.img onto the boot
partition that is generated.  
If you booted temporarily from a boot.img then the new boot.img won't be flashed onto the boot partition.

## QEMU

The kernel update that is installed in the image won't be used, so you have to rebuild the image.

# Anbox

Install and setup Anbox:

```bash
sudo pacman -S anbox anbox-image-aarch64 android-tools
sudo systemctl enable --now anbox-container-manager
systemctl enable --now --user anbox-session-manager
```

and then reboot.

# Cross-compiling packages

If you want to cross-compile packages, you can use the `cross_compile_package.sh` or the `host_compile_package.sh`
script from the https://github.com/arch-beryllium/beryllium-packages repo. You can pass all flags to the scripts that
makepkg accepts.

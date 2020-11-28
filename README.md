# Arch Linux on beryllium (Xiaomi Poco F1)

My efforts to run Arch Linux natively (no [Halium](https://halium.org)) on the Poco F1.  
I only create this script (yet), but the most effort comes from the people working
on https://gitlab.com/sdm845-mainline/sdm845-linux.  
Currently, you can only boot from the SD card, but adding support for internal memory will be coming.

# Building

```bash
./build.sh
```

To speed up package downloads you can use the `LOCAL_MIRROR` environment variable with and value
like `http://192.168.178.30:8080/\$repo/\$arch` with https://github.com/jld3103/arch-repo-mirror as local mirror tool.

# Flashing onto SD card

You need at least an 8 GB SD card, but more is better.  
Everything on the SD card will be deleted so watch out what you are doing.

```bash
./flash_sdcard.sh /dev/sdX
```

# Running

Put the SD card into the device.  
Boot the device to bootloader mode (you might need to reboot it once to bootloader mode if you put the SD card into the
device after it already booted to bootloader mode).  
Boot from a temporary (nothing will be written to the device) boot.img using this script:

```bash
./boot.sh
```

# SSHing into the device

Run this script to ssh into the device:

```bash
./ssh.sh
```

The default password is `123456`.

# Enable USB internet forwarding

This will block WiFi until rebooting on the device.  
Host side:

```bash
./enable_forwarding.sh
```

Device side:

```bash
sudo route add default gw 10.15.19.100
```
pi-tryboot - Raspberry Pi Tryboot Bootloader
============================================

pi-tryboot is a simple *bootloader* for Raspberry Pi. Don't let the word
*bootloader* fool you, it's not - and never will be - a replacement for the
official Raspberry Pi bootloader. Its ultimate goal is to enhance the boot
experience and provide a GBUB-like bootmenu with the capability to boot any
installed kernel with a safety fall-back to a known-good kernel. For that, it
makes use of the firmware's
[tryboot](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#fail-safe-os-updates-tryboot)
feature, hence its name.

**Disclaimer**: This code is still experimental. Use at your own risk.

Why?
----

Preinstalled Ubuntu raspi images use flash-kernel to automatically copy the
latest installed kernel, initrd, DTBs and DT overlays from the system
directories /boot and /lib/firmware to the VFAT partition mounted at
/boot/firmware, from where the Raspberry Pi firmware will pick them up at
boot.

Older kernels can be copied by using flash-kernel's --force option, so
switching between different installed kernels requires a flash-kernel copy
operation. That's not very comfortable and - more importantly - will result in
an unbootable system should the flash-kernel installed kernel turn out to be
bad. Recovery requires manual intervention by pulling the boot media,
attaching it to another computer, mounting the VFAT partition and reinstalling
the flash-kernel backup files. That's really a no-go for development tasks
like testing new kernels.

pi-tryboot aims to solve this problem by providing the ability to boot a
kernel once and fall-back to the default (known good) kernel on subsequent
boots.

How?
----

At boot, the Raspberry Pi firmware reads an internal register and if a
certain bit in that register is set, it will load *tryboot.txt* instead of the
regular *config.txt* and then clear the bit. Subsequent boots will thus fall
back to using *config.txt*. The register content is preserved across soft
reboots but not power cycles. To set the bit, the Pi needs to be rebooted
with:

    $ reboot '0 tryboot'

This will instruct the kernel to set the bit at shutdown so that the following
boot uses *tryboot.txt*.

pi-tryboot makes use of this capability by generating a special *tryboot.txt*
file depending on the kernel that should be rebooted into. At a high-level
this special *tryboot.txt* is just a copy of the original *config.txt* with
modified kernel and initrd statements.

pi-tryboot provides a couple of commands (similar to GRUB) that hide all this
complexity from the user.

Example Usage
-------------

Limitations and Requirements
----------------------------

- Only tested with (classic) preinstalled Ubuntu raspi images.
- Requires Raspberry Pi firmware newer than Oct 2020 (see references below).
- Requires downstream kernel patches (see references below).
- The number of tryboot installable kernels depends on the size of the VFAT
  partition.

References
----------

- [Daily Ubuntu pi-tryboot package builds](https://launchpad.net/~juergh/+archive/ubuntu/pi-tryboot)
- [Preinstalled Ubuntu raspi images (daily)](http://cdimage.ubuntu.com/daily-preinstalled/current)
- [Preinstalled Ubuntu raspi images (release)](https://ubuntu.com/download/raspberry-pi)
- [Raspberry Pi firmware tryboot support](https://github.com/raspberrypi/linux/pull/3937)
- [Kernel tryboot support](https://github.com/raspberrypi/linux/commit/757666748ebf69dc161a262faa3717a14d68e5aa)
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

[Daily Ubuntu package builds](https://launchpad.net/~juergh/+archive/ubuntu/pi-tryboot)

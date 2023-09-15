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

**Disclaimer**: pi-tryboot is only tested on
[Ubuntu](https://ubuntu.com/raspberry-pi) (classic).

Why?
----

How?
----

Example Usage
-------------

References
----------

- [Daily Ubuntu pi-tryboot package builds](https://launchpad.net/~juergh/+archive/ubuntu/pi-tryboot)
- [Preinstalled Ubuntu raspi images (daily)](http://cdimage.ubuntu.com/daily-preinstalled/current)
- [Preinstalled Ubuntu raspi images (release)](https://ubuntu.com/download/raspberry-pi)

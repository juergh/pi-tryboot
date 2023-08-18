#!/bin/sh
#
# Simple helper functions
#

# TB:  Tryboot bootloader
# TBE: Tryboot bootloader entry

set -u

# ----------------------------------------------------------------------------
# TB helpers

#
# Exit handler
#
tb_exit()
{
	rc=${?}

	tb_untrap_exit

	if [ ${rc} -ne 0 ] ; then
		echo "-- Script failed" >&2
	fi

	exit "${rc}"
}

#
# Remove exit handler
#
tb_untrap_exit()
{
	trap - EXIT INT TERM HUP
}

#
# Install exit handler
#
tb_trap_exit()
{
	trap tb_exit EXIT INT TERM HUP
}

#
# Check if tryboot bootloader is enabled
#
tb_enabled()
{
	grep -q "# RPI-TRYBOOT" "${FW_DIR}"/config.txt
}

#
# Enable tryboot bootloader
#
tb_enable()
{
	if ! tb_enabled ; then
		cp "${FW_DIR}"/tryboot/tryboot/config.txt "${FW_DIR}"/config.txt
	fi
}

#
# Disable tryboot bootloader
#
tb_disable()
{
	if tb_enabled ; then
		cp "${FW_DIR}"/config.orig.txt "${FW_DIR}"/config.txt
	fi
}

#
# Source /etc/default config files
#
tb_source_default_configs()
{
	for cfg in /etc/default/tryboot /etc/default/tryboot.d/* ; do
		if [ -e "${cfg}" ] ; then
			# shellcheck disable=SC1090
			. "${cfg}"
		fi
	done
}

# ----------------------------------------------------------------------------
# TBE inventory helpers

#
# Check if a TBE exists
#
tb_tbe_exists()
{
	tbe=${1}

	test -e "${TB_DIR}"/"${tbe}"/config.txt
}

#
# Return the list of available TBEs
#
tb_print_tbe_list()
{
	for tbe_dir in "${TB_DIR}"/* ; do
		tbe=${tbe_dir##*/}
		if [ "${tbe}" != "tryboot" ] && [ -e "${tbe_dir}"/config.txt ] ; then
			echo "${tbe}"
		fi
	done
}

#
# Return the TBE for the provided index
#
tb_print_tbe_from_index()
{
	idx=${1}

	if [ "${idx}" -gt 0 ] 2>/dev/null ; then
		tb_print_tbe_list | sed -n "${idx}p"
	fi
}

#
# Return the default TBE
#
tb_print_default_tbe()
{
	if [ -e "${TB_DIR}"/default ] ; then
		tbe=$(head -1 "${TB_DIR}"/default)
		if tb_tbe_exists "${tbe}" ; then
			echo "${tbe}"
			return
		fi
	fi

	# No saved default TBE, so use the first in the list
	tb_print_tbe_from_index 1
}

# ----------------------------------------------------------------------------
# TBE boot helpers

#
# Print the boot menu
#
tb_print_boot_menu()
{
	tbe_default=$(tb_print_default_tbe)

	echo "------------------------------------------------------------"
	echo "    Idx   Entry"
	echo "------------------------------------------------------------"

	idx=1
	tb_print_tbe_list | while read -r tbe ; do
		if [ "${tbe}" = "${tbe_default}" ] ; then
			def="*"
		else
			def=" "
		fi

		printf "%s   %3d   %s\n" "${def}" "${idx}" "${tbe}"
		idx=$((idx + 1))
	done

	echo "------------------------------------------------------------"
}

#
# Boot the provided TBE
#
tb_boot_tbe()
{
	tbe=${1}

	config=${TB_DIR}/${tbe}/config.txt

	if ! [ -e "${config}" ] ; then
		echo "-- No such tryboot entry: ${tbe}" >&2
		return 1
	fi

	cp "${config}" "${FW_DIR}"/tryboot.txt
	reboot "0 tryboot"
}

# ----------------------------------------------------------------------------
# TBE install, update and remove helpers

#
# Install the tryboot TBE
#
tb_install_tryboot_tbe()
{
	tbe_dir=${TB_DIR}/tryboot

	rm -rf "${tbe_dir}"
	mkdir -p "${tbe_dir}"

	# Copy firmware files from the package
	cp -r "${PKG_DIR}"/tryboot/* "${TB_DIR}"/tryboot
}

#
# Install the system-default TBE
#
tb_install_system_default_tbe()
{
	tbe_dir=${TB_DIR}/system-default

	rm -rf "${tbe_dir}"
	mkdir -p "${tbe_dir}"
}

#
# Install a kernel TBE
#
tb_install_kernel_tbe()
{
	tbe=${1}
	tbe_dir=${TB_DIR}/${tbe}

	if ! [ -e "${BOOT_DIR}"/vmlinuz-"${tbe}" ] ; then
		echo "-- Invalid kernel entry: ${tbe}" >&2
		return 1
	fi

	rm -rf "${tbe_dir}"
	mkdir -p "${tbe_dir}"

	vmlinuz=${BOOT_DIR}/vmlinuz-${ENTRY}
	initrd=${BOOT_DIR}/initrd.img-${ENTRY}

	# Copy the kernel and initrd
	cp "${vmlinuz}" "${tbe_dir}"/vmlinuz
	cp "${initrd}" "${tbe_dir}"/initrd.img

	# Copy the DTBS and overlays
	for dtb_dir in /lib/firmware/"${tbe}"/device-tree \
	               /usr/lib/linux-image-"${tbe}" ; do
		if [ -d "${dtb_dir}" ] ; then
			break
		fi
	done
	cp "${dtb_dir}"/broadcom/bcm27* "${tbe_dir}"
	cp -r "${dtb_dir}"/overlays "${tbe_dir}"
}

#
# Create the TBE's config.txt
#
tb_create_tbe_config_txt()
{
	tbe=${1} templ=${2}
	tbe_dir=${TB_DIR}/${tbe}

	# Determine kernel architecture
	if file "${tbe_dir}"/vmlinuz | grep -q "zImage" ; then
		arm_64bit=0
	else
		arm_64bit=1
	fi

	TRYBOOT_ENTRY=${tbe} \
	ARM_64BIT=${arm_64bit} \
		envsubst < /etc/tryboot.d/"${templ}" > "${tbe_dir}"/config.txt
}

#
# Update the tryboot TBE (config.txt and cmdline.txt)
#
tb_update_tryboot_tbe()
{
	tbe_dir=${TB_DIR}/tryboot

	# config.txt
	tb_create_tbe_config_txt tryboot config.tryboot.txt

	# cmdline.txt
	tb_source_default_configs
	echo "${TRYBOOT_TRYBOOT_CMDLINE_LINUX}" > "${tbe_dir}"/cmdline.txt
}

#
# Update the system-default TBE (config.txt only)
#
tb_update_system_default_tbe()
{
	tbe_dir=${TB_DIR}/system-default
	config_orig=${FW_DIR}/config.orig.txt

	# Back up the original config.txt
	if ! [ -e "${config_orig}" ] ; then
		cp "${FW_DIR}"/config.txt "${config_orig}"
	fi

	# Set the default commandline
	if grep -q "__CMDLINE__" /etc/default/tryboot ; then
		cmdline=$(head -1 "${FW_DIR}"/cmdline.txt)
		sed -i "s/__CMDLINE__/${cmdline}/" /etc/default/tryboot
	fi

	# config.txt
	cp "${config_orig}" "${tbe_dir}"/config.txt
}

#
# Update a kernel TBE (config.txt and cmdline.txt)
#
tb_update_kernel_tbe()
{
	tbe=${1}
	tbe_dir=${TB_DIR}/${tbe}

	# config.txt
	tb_create_tbe_config_txt "${tbe}" config.kernel.txt

	# cmdline.txt
	tb_source_default_configs
	echo "${TRYBOOT_CMDLINE_LINUX}" > "${tbe_dir}"/cmdline.txt
}

#
# Update a TBE (config.txt amd cmdline.txt)
#
tb_update_tbe()
{
	tbe=${1}

	case "${tbe}" in
		tryboot)        tb_update_tryboot_tbe ;;
		system-default) tb_update_system_default_tbe ;;
		*)              tb_update_kernel_tbe "${tbe}" ;;
	esac
}

#
# Remove a TBE
#
tb_remove_tbe()
{
	tbe=${1}
	tbe_dir=${TB_DIR}/${tbe}

	rm -rf "${tbe_dir}"
}

# ----------------------------------------------------------------------------
# Main entry point
#

PKG_DIR=/usr/lib/rpi-tryboot

BOOT_DIR=/boot
if [ -e /boot/firmware/config.txt ] ; then
	FW_DIR=/boot/firmware
else
	FW_DIR=/boot
fi
TB_DIR=${FW_DIR}/tryboot

# Install an exit handler
tb_trap_exit

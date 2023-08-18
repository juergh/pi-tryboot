#!/bin/sh
#
# Simple helper functions
#

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
tb_get_tbe_list()
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
tb_get_tbe_from_index()
{
	idx=${1}

	if [ "${idx}" -gt 0 ] 2>/dev/null ; then
		tb_get_tbe_list | sed -n "${idx}p"
	fi
}

#
# Return the default TBE
#
tb_get_default_tbe()
{
	if [ -e "${TB_DIR}"/default ] ; then
		tbe=$(head -1 "${TB_DIR}"/default)
		if tb_tbe_exists "${tbe}" ; then
			echo "${tbe}"
			return
		fi
	fi

	# No saved default TBE, so use the first in the list
	tb_get_tbe_from_index 1
}

#
# Print the boot menu
#
tb_print_boot_menu()
{
	tbe_default=$(tb_get_default_tbe)

	echo "------------------------------------------------------------"
	echo "    Idx   Entry"
	echo "------------------------------------------------------------"

	idx=1
	tb_get_tbe_list | while read -r tbe ; do 
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
# Check if tryboot bootloader is enabled
#
tb_enabled()
{
	grep -q "# RPI-TRYBOOT" "${FW_DIR}"/config.txt
}

#
# Enable the tryboot bootloader
#
tb_enable()
{
	if tb_enabled ; then
		return
	fi

	if ! [ -e "${FW_DIR}"/config.orig.txt ] ; then
		cp "${FW_DIR}"/config.txt "${FW_DIR}"/config.orig.txt
	fi
	cp "${FW_DIR}"/tryboot/tryboot/config.txt "${FW_DIR}"/config.txt
}

#
# Disable the tryboot bootloader
#
tb_disable()
{
	if tb_enabled ; then
		cp "${FW_DIR}"/config.orig.txt "${FW_DIR}"/config.txt
	fi
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

#
# Main entry point
#

if [ -e /boot/firmware/config.txt ] ; then
	FW_DIR=/boot/firmware
else
	FW_DIR=/boot
fi

TB_DIR=${FW_DIR}/tryboot

# Install an exit handler
tb_trap_exit

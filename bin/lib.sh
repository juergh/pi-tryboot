#!/bin/sh
#
# Simple helper functions
#

tb_print_menu()
{
	# Saved default
	tbe_default=
	if [ -e "${TB_DIR}"/default ] ; then
		tbe_default=$(head -1 "${TB_DIR}")
		if ! [ -e "${TB_DIR}"/"{tbe_default}"/config.txt ] ; then
			tbe_default=
		fi
	fi

	echo "------------------------------------------------------------"
	echo "  Idx   Entry"
	echo "------------------------------------------------------------"

	idx=1
	for tbe_dir in "${TB_DIR}"/* ; do
		tbe=${tbe_dir##*/}
		if [ "${tbe}" = "tryboot" ] || ! [ -e "${tbe_dir}"/config.txt ] ; then
			continue
		fi

		if [ -z "${tbe_default}" ] && [ ${idx} -eq  1 ] ; then
			def="*"
		elif [ -n "${tbe_default}" ] && [ "${tbe}" = "${tbe_default}" ] ; then
			def="*"
		else
			def=" "
		fi

		printf "%s %3d   %s\n" "${def}" "${idx}" "${tbe}"
		idx=$((idx + 1))
	done

	echo "------------------------------------------------------------"
}

#
# Set globals
#

if [ -e /boot/firmware/config.txt ] ; then
	FW_DIR=/boot/firmware
else
	FW_DIR=/boot
fi

TB_DIR=${FW_DIR}/tryboot

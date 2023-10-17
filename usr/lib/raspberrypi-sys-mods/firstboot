#!/bin/bash

reboot_pi () {
  umount "$FWLOC"
  mount / -o remount,ro
  sync
  reboot -f "$BOOT_PART_NUM"
  sleep 5
  exit 0
}

get_variables () {
  ROOT_PART_DEV=$(findmnt / -no source)
  ROOT_DEV_NAME=$(lsblk -no pkname  "$ROOT_PART_DEV")
  ROOT_DEV="/dev/${ROOT_DEV_NAME}"

  BOOT_PART_DEV=$(findmnt "$FWLOC" -no source)
  BOOT_PART_NAME=$(lsblk -no kname "$BOOT_PART_DEV")
  BOOT_DEV_NAME=$(lsblk -no pkname  "$BOOT_PART_DEV")
  BOOT_PART_NUM=$(cat "/sys/block/${BOOT_DEV_NAME}/${BOOT_PART_NAME}/partition")

  OLD_DISKID=$(fdisk -l "$ROOT_DEV" | sed -n 's/Disk identifier: 0x\([^ ]*\)/\1/p')
}

fix_partuuid() {
  if [ "$BOOT_PART_NUM" != "1" ]; then
    return 0
  fi
  mount -o remount,rw "$ROOT_PART_DEV"
  mount -o remount,rw "$BOOT_PART_DEV"
  DISKID="$(dd if=/dev/hwrng bs=4 count=1 status=none | od -An -tx4 | cut -c2-9)"
  fdisk "$ROOT_DEV" > /dev/null <<EOF
x
i
0x$DISKID
r
w
EOF
  if [ "$?" -eq 0 ]; then
    sed -i "s/${OLD_DISKID}/${DISKID}/g" /etc/fstab
    sed -i "s/${OLD_DISKID}/${DISKID}/" "$FWLOC/cmdline.txt"
    sync
  fi

  mount -o remount,ro "$ROOT_PART_DEV"
  mount -o remount,ro "$BOOT_PART_DEV"
}

regenerate_ssh_host_keys () {
  mount -o remount,rw /
  /usr/lib/raspberrypi-sys-mods/regenerate_ssh_host_keys
  RET="$?"
  mount -o remount,ro /
  return "$RET"
}

apply_custom () {
  CONFIG_FILE="$1"
  mount -o remount,rw /
  mount -o remount,rw "$FWLOC"
  if ! python3 -c "import toml" 2> /dev/null; then
    FAIL_REASON="custom.toml provided, but python3-toml is not installed\n$FAIL_REASON"
  else
    set -o pipefail
    /usr/lib/raspberrypi-sys-mods/init_config "$CONFIG_FILE" |& tee /run/firstboot.log | while read -r line; do
        MSG="$MSG\n$line"
        whiptail --infobox "$MSG" 20 60
    done
    if [ "$?" -ne 0 ]; then
      mv /run/firstboot.log /var/log/firstboot.log
      FAIL_REASON="Failed to apply customisations from custom.toml\n\nLog file saved as /var/log/firstboot.log\n$FAIL_REASON"
    fi
    set +o pipefail
  fi
  rm -f "$CONFIG_FILE"
  mount -o remount,ro "$FWLOC"
  mount -o remount,ro /
}

main () {
  get_variables

  whiptail --infobox "Generating SSH keys..." 20 60
  regenerate_ssh_host_keys

  if [ -f "$FWLOC/custom.toml" ]; then
    MSG="Applying customisations from custom.toml...\n"
    whiptail --infobox "$MSG" 20 60
    apply_custom "$FWLOC/custom.toml"
  fi

  whiptail --infobox "Fix PARTUUID..." 20 60
  fix_partuuid

  return 0
}

mountpoint -q /proc || mount -t proc proc /proc
mountpoint -q /sys || mount -t sysfs sys /sys
mountpoint -q /run || mount -t tmpfs tmp /run
mkdir -p /run/systemd

mount / -o remount,ro

if ! FWLOC=$(/usr/lib/raspberrypi-sys-mods/get_fw_loc); then
  whiptail --msgbox "Could not determine firmware partition" 20 60
  poweroff -f
fi

mount "$FWLOC" -o rw

sed -i 's| init=/usr/lib/raspberrypi-sys-mods/firstboot||' "$FWLOC/cmdline.txt"
sed -i 's| sdhci\.debug_quirks2=4||' "$FWLOC/cmdline.txt"

if ! grep -q splash "$FWLOC/cmdline.txt"; then
  sed -i "s/ quiet//g" "$FWLOC/cmdline.txt"
fi
mount "$FWLOC" -o remount,ro
sync

main

if [ -z "$FAIL_REASON" ]; then
  whiptail --infobox "Rebooting in 5 seconds..." 20 60
  sleep 5
else
  whiptail --msgbox "Failed running firstboot:\n${FAIL_REASON}" 20 60
fi

reboot_pi

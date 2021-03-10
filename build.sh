#!/bin/bash
#
# Version: 1.3.1
# Description: ISO creation script
# Source: https://github.com/fuckbian/mkiso
# Author: Adil Gurbuz (beucismis) <beucismis@tutamail.com>
#


NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'


if [[ "$(id -u)" != 0 ]]; then
  echo -e "${RED}E: Requires root permissions!${NC}" > /dev/stderr
  exit 1
fi

echo -e "${YELLOW}I: Installing dependices ...${NC}"
apt -qq install debootstrap xorriso squashfs-tools tree -y

echo -e "${YELLOW}I: Creating a chroot ...${NC}"
mkdir sid-chroot
chown root sid-chroot
debootstrap --no-merged-usr --arch=amd64 sid sid-chroot https://deb.debian.org/debian

for i in dev dev/pts proc sys; do mount -o bind /$i sid-chroot/$i; done

echo -e "${YELLOW}I: Updating source.list ...${NC}"
echo "deb http://deb.debian.org/debian/ unstable main contrib non-free" > sid-chroot/etc/apt/source.list
echo "deb http://security.debian.org/debian-security buster/updates main contrib non-free" >> sid-chroot/etc/apt/source.list
echo "deb http://deb.debian.org/debian/ buster-updates main contrib non-free" >> sid-chroot/etc/apt/source.list

echo -e "${YELLOW}I: Updates and upgrades ...${NC}"
chroot sid-chroot apt -qq update -y
chroot sid-chroot apt -qq upgrade -y
chroot sid-chroot apt -qq dist-upgrade -y

echo -e "${YELLOW}I: Installing the Linux kernel ...${NC}"
chroot sid-chroot apt -qq install linux-headers-amd64 linux-image-amd64 -y

echo -e "${YELLOW}I: Installing the GRUB ...${NC}"
chroot sid-chroot apt -qq install grub-pc-bin grub-efi-ia32-bin grub-efi -y

echo -e "${YELLOW}I: Installing the live boot packages ...${NC}"
chroot sid-chroot apt -qq install live-config live-boot -y

echo -e "${YELLOW}I: Installing the Openbox, Tint2 and LightDM ...${NC}"
chroot sid-chroot apt -qq install xorg xinit openbox tint2 lightdm feh -y

echo -e "${YELLOW}I: Installing the other packages ...${NC}"
chroot sid-chroot apt -qq install xfce4-terminal firefox network-manager -y
chroot sid-chroot apt -qq install apt-listbugs papirus-icon-theme lxappearance pavucontrol volumeicon -y

echo -e "${YELLOW}I: Installing the config files ...${NC}"
chroot sid-chroot/tmp git clone https://github.com/fuckbian/configs
chroot sid-chroot/tmp ./configs/copy.sh

echo -e "${YELLOW}I: Installing the live installer ...${NC}"
chroot sid-chroot apt -qq install devscripts
chroot sid-chroot/tmp git clone https://gitlab.com/ggggggggggggggggg/17g
chroot sid-chroot/tmp/17g mk-build-deps --install
chroot sid-chroot/tmp/17g debuild -us -uc -b
chroot sid-chtoot/tmp apt -qq install ./17g*.deb

echo -e "${YELLOW}I: Installing the drivers ...${NC}"
chroot sid-chroot apt -qq install firmware-amd-graphics firmware-atheros firmware-b43-installer firmware-b43legacy-installer firmware-bnx2 firmware-bnx2x firmware-brcm80211 firmware-cavium firmware-intel-sound firmware-intelwimax firmware-ipw2x00 firmware-ivtv firmware-iwlwifi firmware-libertas firmware-linux firmware-linux-free firmware-linux-nonfree firmware-misc-nonfree firmware-myricom firmware-netxen firmware-qlogic firmware-realtek firmware-samsung firmware-siano firmware-ti-connectivity firmware-zd1211 -y

umount -lf -R sid-chroot/* 2>/dev/null

echo -e "${YELLOW}I: Cleaning ...${NC}"
chroot sid-chroot apt -qq clean
rm -rf sid-chroot/tmp/*
rm -f sid-chroot/root/.bash_history
rm -rf sid-chroot/var/lib/apt/lists/*
find sid-chroot/var/log/ -type f | xargs rm -f

echo -e "${YELLOW}I: Chroot is packecing ...${NC}"
mkdir isowork
mksquashfs sid-chroot filesystem.squashfs -comp gzip -wildcards
mkdir -p isowork/live
mv filesystem.squashfs isowork/live/filesystem.squashfs
cp -pf sid-chroot/boot/initrd.img-* isowork/live/initrd.img
cp -pf sid-chroot/boot/vmlinuz-* isowork/live/vmlinuz

echo -e "${YELLOW}I: Creating grub.cfg ...${NC}"
mkdir -p isowork/boot/grub/
echo 'menuentry "Fuckbian 64-bit" --class debian {' > isowork/boot/grub/grub.cfg
echo "    linux /live/vmlinuz boot=live live-config live-media-path=/live quiet splash --" >> isowork/boot/grub/grub.cfg
echo "    initrd /live/initrd.img" >> isowork/boot/grub/grub.cfg
echo "}" >> isowork/boot/grub/grub.cfg

echo -e "${YELLOW}I: Tree ...${NC}"
tree isowork

echo -e "${YELLOW}I: ISO file is making ...${NC}"
date=$(date -d "today" +"%Y%m%d")
grub-mkrescue isowork -o fuckbian-live-$date-amd64-openbox+nonfree.iso

echo -e "${GREEN}I: Done!${NC}"

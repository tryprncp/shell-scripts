#!/bin/bash

set -e

# Choose Arch Linux installation type:
# 1) Minimal install, 2) With HyDE, 3) With i3WM
TYPE=""

# Set hostname
HOSTNAME=""

# Set root password
ROOT_PASSWORD=""

# Set username and password
USERNAME=""
USER_PASSWORD=""

# Set disk name (run lsblk to identify your disk)
DISK=""

# Set variable based on disk name
if [[ $DISK == nvme* ]]; then
    PART="${DISK}p"
else
    PART="${DISK}"
fi

# Remove existing partitions in the disk
for PART_NUM in $(parted "$DISK" --script print | awk '/^ / {print $1}')
do
  parted "$DISK" --script rm "$PART_NUM"
done

# Create partitions and format the partitions
parted /dev/"$DISK" --script mklabel gpt
parted /dev/"$DISK" --script mkpart primary fat32 1MiB 500MiB
parted /dev/"$DISK" --script set 1 esp on
parted /dev/"$DISK" --script mkpart primary ext4 500MiB 100%
# Format partition 1 to fat32 filesystem
mkfs.fat -F 32 /dev/"${PART}"1
# Format partition 2 to ext4 filesystem
mkfs.ext4 /dev/"${PART}"2

# Mount the partitions
mount --mkdir /dev/${PART}1 /boot/efi
mount /dev/"${PART}"2 /mnt

# Initialize pacman-key
pacman-key --init
pacman-key --populate archlinux

# Install reflector and setup mirrorlist
pacman -Syy
pacman -S --noconfirm reflector
reflector -c "SG" -f 10 -l 10 -n 10 --save /etc/pacman.d/mirrorlist

# Install essential packages using pacstrap
while ! pacstrap -K --needed --noconfirm /mnt base base-devel linux linux-firmware sof-firmware intel-ucode; do :; done

# Generate fstab
genfstab -U /mnt >>/mnt/etc/fstab

# Create a post-install script to be performed by arch-chroot
cat <<EOF_CHROOT >/mnt/root/chroot_script.sh
#!/bin/bash
set -e

# Install essential packages
while ! pacman -Syu --needed --noconfirm git grub efibootmgr neovim networkmanager man-db sudo; do :; done

# Set timezone
ln -sf /usr/share/zoneinfo/Asia/Manila /etc/localtime
hwclock --systohc
systemctl enable systemd-timesyncd
systemctl start systemd-timesyncd

# Set locale and language
sed -i 's/#en_PH.UTF-8 UTF-8/en_PH.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo LANG=en_PH.UTF-8 > /etc/locale.conf
export LANG=en_PH.UTF-8

# Setup hostname
echo $HOSTNAME > /etc/hostname
cat <<HOSTS > /etc/hosts
127.0.0.1  localhost
::1  localhost
127.0.0.1  $HOSTNAME
HOSTS

# Install grub on partition 1
grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg

# Setup root and user credentials
echo -e "$ROOT_PASSWORD\n$ROOT_PASSWORD" | passwd
useradd -m $USERNAME
echo -e "$USER_PASSWORD\n$USER_PASSWORD" | passwd $USERNAME
usermod -aG wheel,audio,video,storage $USERNAME
echo "$USERNAME ALL=(ALL) ALL" > /etc/sudoers.d/$USERNAME

# Ignore power button
sed -i '/^#HandlePowerKey=ignore/s/^#//' /etc/systemd/logind.conf

# Enable network manager
systemctl enable NetworkManager
EOF_CHROOT

# Append additional commands to chroot_script.sh to install HyDE if the $TYPE is 2
if [ "$TYPE" == "2" ]; then
    echo "su - $USERNAME" >>/mnt/root/chroot_script.sh
    echo "git clone --depth 1 https://github.com/tryprncp/hyprdots HyDE && ./HyDE/Scripts/install.sh" >>/mnt/root/chroot_script.sh
fi

# Append additional commands to chroot_script.sh to install i3WM if the $TYPE is 3
if [ "$TYPE" == "3" ]; then
    echo "su - $USERNAME" >>/mnt/root/chroot_script.sh
    echo "git clone --depth 1 https://github.com/tryprncp/i3WM && ./i3WM/Scripts/install.sh" >>/mnt/root/chroot_script.sh
fi

# Execute the script using arch-chroot and remove it afterwards
arch-chroot /mnt /bin/bash /root/chroot_script.sh
rm /mnt/root/chroot_script.sh

# Unmount filesystem
umount -l /mnt

# Execute shutdown if everything is successful
if [ $? -eq 0 ]; then
    shutdown now
else
    exit 2
fi

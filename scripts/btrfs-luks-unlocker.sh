#!/bin/sh
## LUKS remote decrypt for Ubuntu 20.04 - by BinaryShrub

# NOTES:
# Tailor line 47 to your system before running!
# Use at your own risk!

bold=$(tput bold)
normal=$(tput sgr0)

echo; echo "$bold>>$normal Installing/Updating dropbear-initramfs ..."
sudo apt -y install dropbear-initramfs

echo; echo "$bold>>$normal Creating initramfs hook ..."
HOOK="/usr/share/initramfs-tools/hooks/btrfs-unlocker"

sudo sh -c "cat >$HOOK" <<- HOOK
#!/bin/sh

PREREQ=""

prereqs()
{
    echo "$PREREQ"
}

case "$1" in
    prereqs)
        prereqs
        exit 0
        ;;
esac

. /usr/share/initramfs-tools/hook-functions

echo "update-initramfs: Creating /bin/unlock script and shortcut"

UNLOCKER="\$DESTDIR/bin/unlock"

cat >\$UNLOCKER <<- UNLOCKER
#!/bin/sh

# WARNING: Locking directory /run/cryptsetup is missing!
mkdir -p "/run/cryptsetup"

# decrypt drives
/sbin/cryptsetup luksOpen /dev/sda3 sda3_crypt

# find BTRFS after decrypt
btrfs device scan

# kill interactive shell to continue the boot process
echo ""
echo "⏳ Booting ..."
echo ""
kill -9 \\\$(ps | grep "sh -i" | awk '{print \\\$1}') &>/dev/null
UNLOCKER

chmod +x \$UNLOCKER

SHORTCUT="\$DESTDIR/\$(ls \$DESTDIR | grep root)/unlock"

cat >\$SHORTCUT <<- SHORTCUT
#!/bin/sh

/bin/unlock
SHORTCUT

chmod +x \$SHORTCUT
HOOK

sudo chmod +x $HOOK

echo "'$HOOK' created"

echo; echo "$bold>>$normal Configuring ssh key authorization ..."
AUTH_KEYS_PATH="$(readlink -f ~)/.ssh/authorized_keys"
if [ -f $AUTH_KEYS_PATH ]
then
  sudo cp $AUTH_KEYS_PATH /etc/dropbear-initramfs/authorized_keys
  echo "'/etc/dropbear-initramfs/authorized_keys' replaced with '$AUTH_KEYS_PATH'"
else
  echo "⚠️  WARNING: No authorized_keys set! '$AUTH_KEYS_PATH' does not exist."
fi

echo; echo "$bold>>$normal Rebuilding initramfs ..."
sudo update-initramfs -u

echo; echo "$bold🎉 Done! Reboot to initramfs and run \`unlock\` 💪"; echo
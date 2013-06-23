#!/system/bin/sh

# store-mac-addr -- reads configured wifi MAC address and writes it into nvs
# file for use by the wl12xx driver

ROM_NVS=/system/etc/firmware/ti-connectivity/wl1271-nvs_127x.bin
ORIG_NVS=/data/misc/wifi/wl1271-nvs.bin.orig
NEW_NVS=/data/misc/wifi/wl1271-nvs.bin

# Echoes the substring of $1 starting at index $2 of length $3
substr() {
	echo "$1" | dd bs=1 skip="$2" count="$3" 2>/dev/null
}

umask 0022

# Don't bother updating the nvs file if the one shipped in the ROM hasn't
# changed since the last boot
cmp "$ROM_NVS" "$ORIG_NVS" > /dev/null 2>&1 && exit 0

# Get the MAC address
macaddr=$(cat /rom/devconf/MACAddress)
[ $macaddr ] || exit 1

# The MAC address is stored in the nvs file in two pieces: the four
# least-significant bytes in little-endian order starting at byte offset 3
# (indexed to 0), and the two most-significant bytes in little-endian order
# starting at byte offset 10.
#
# We're using echo -ne to write these bytes to the file, so parse the MAC
# address to produce the escape sequences needed to echo the bytes.
b0=$(substr "$macaddr" 0 2)
b1=$(substr "$macaddr" 2 2)
b2=$(substr "$macaddr" 4 2)
b3=$(substr "$macaddr" 6 2)
b4=$(substr "$macaddr" 8 2)
b5=$(substr "$macaddr" 10 2)
lowbytes="\x$b5\x$b4\x$b3\x$b2"
highbytes="\x$b1\x$b0"

# Create the new nvs file by copying over the ROM's copy byte by byte,
# replacing only the pieces containing the MAC address
dd if="$ROM_NVS" of="$NEW_NVS" bs=1 count=3
echo -ne "$lowbytes" >> "$NEW_NVS"
dd if="$ROM_NVS" of="$NEW_NVS" bs=1 skip=7 seek=7 count=3
echo -ne "$highbytes" >> "$NEW_NVS"
dd if="$ROM_NVS" of="$NEW_NVS" bs=1 skip=12 seek=12

# Store the unmodified nvs file for reference
cp "$ROM_NVS" "$ORIG_NVS"

exit 0
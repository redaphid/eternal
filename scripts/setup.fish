set -U DISK /dev/disk/by-id/ata-QEMU_HARDDISK_QM00009 #target disk
set -U SRC_DISK /dev/disk/by-id/ata-QEMU_HARDDISK_QM00007 #SRC_DISK

zpool import -N bpool

sgdisk --zap-all $DISK #format
sgdisk     -n1:1M:+512M   -t1:EF00 $DISK #EFI
sgdisk     -n2:0:+2G      -t2:BE00 $DISK #boot pool
sgdisk     -n3:0:0        -t3:BF00 $DISK #zfs main

pv < $SRC_DISK-part1 > $DISK-part1
# pv < $SRC_DISK-part2 > $DISK-part2
parted --script $DISK name 1 EFI

zpool list -v -H -P
zpool attach bpool $SRC_DISK-part2 $DISK-part2
zpool attach rpool $SRC_DISK-part3 $DISK-part3
watch zpool status #wait...


zpool offline bpool $DISK-part2
zpool offline rpool $DISK-part3

zpool detach bpool $DISK-part2
zpool detach rpool $DISK-part3

zpool clear rpool
zpool clear bpool
#zpool export bpool

#sudo apt install refind

#!/usr/bin/env fish

set EFI_PARTITION_TYPE EF00
set _ZFS_PARTITION_TYPE BE00
function format_efi_partition -a destination_disk partition_number size -d "allocate and format EFI Partition."
    string length -q partition_number; or panic "must specify a destination disk!"
    string length -q destination_disk; or panic "must specify a destination partition!"

    set destination_partition $destination_disk-part1
    set -e destination_disk
    
    string length -q $size; or begin
        set size "512M"
        echo "Setting EFI size to the default of $size"
    end
    confirm "EFI Formatting $destination_partition ($size). Sound good?" or panic "Aborted EFI formatting"

    sgdisk -n1:1M:+512M -t1:$EFI_PARTITION_TYPE $target_disk #EFI
    parted --script $destination_disk name 1 EFI
    echo "EFI partition done."
end

function prep_new_disk -a destination_disk -d "wipe the disk, and put our partitions on it."
    string length -q $destination_disk; or panic "must specify a destination disk!"
    confirm "about to destroy $destination_disk. We good?"; or panic "We weren't good."
    sgdisk --zap-all $destination_disk
    echo "zapped"

    set partition_number 1
    
    confirm "EFI partition on $partition_number?"; and begin
        format_efi_partition $destination_disk $partition_number
        echo "EFI done."
        set partition_number (math $partition_number + 1)
    end
    
    confirm "boot pool on $partition_number?"; and begin
        sgdisk -n$partition_number:0:+2G -t$partition_number:$ZFS_PARTITION_TYPE $destination_disks #boot pool
        set partition_number (math $partition_number + 1)
    end

    confirm "root pool on $partition_number?"; and begin
        sgdisk -n$partition_number:0:0 -t$partition_number:$ZFS_PARTITION_TYPE $destination_disk #zfs main
    end
end

function format_partitions -a source_disk -a target_disk -d "Format the drive. Replace partition table"
    zpool import -N bpool
    set source_partition "$source_disk-part1" #safer than assuming it's a partition.

    sgdisk --zap-all $target_disk #format
    sgdisk -n1:1M:+512M -t1:EF00 $target_disk #EFI
    sgdisk -n2:0:+2G -t2:BE00 $target_disk #boot pool
    sgdisk -n3:0:0 -t3:BF00 $target_disk #zfs main
    pv <$SRC_DISK-part1 >$target_disk-part1
    # pv < $SRC_DISK-part2 > $target_disk-part2
    parted --script $target_disk name 1 EFI

    zpool list -v -H -P
    zpool attach bpool $SRC_DISK-part2 $target_disk-part2
    zpool attach rpool $SRC_DISK-part3 $target_disk-part3
    watch zpool status #wait...


    zpool offline bpool $target_disk-part2
    zpool offline rpool $target_disk-part3

    zpool detach bpool $target_disk-part2
    zpool detach rpool $target_disk-part3

    zpool clear rpool
    zpool clear bpool
end

function panic -a msg
    set_color red
    echo $argv 1>&2
    set_color normal
    exit 1
end

function confirm -a question -d "ask user for confirmation. status code"
    while true
        read -l -P "$question [y/N] " confirm
        switch $confirm
            case Y y
                return 0
            case '' N n
                return 1
        end
    end
end

function main -a source_disk target_disk -d "Eternal-ify from source->target disk"
    string length -q $source_disk; or panic "must specify a source disk!"    
    set source_partition $source_disk-part1
    set -e source_disk
    echo "Source boot partition: $source_partition $source_disk"
    string length -q $target_disk; or panic "must specify a target disk!"
    echo "Target: $target_disk"
    string match -q "*Force*" $target_disk; and panic "I think this Eternal's HD. If you're so sure it's not, then edit me."
    confirm "Wanna do this?"; or exit 1
    echo "Let's go!"


end
status is-interactive; or main $argv
#zpool export bpool

#sudo apt install refind

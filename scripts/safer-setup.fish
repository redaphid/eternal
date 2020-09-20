#!/usr/bin/env fish

set EFI_PARTITION_TYPE EF00
set _ZFS_PARTITION_TYPE BE00

function not_empty -a variable -d "checks if a value is empty"
    string length -q -- $variable
end

function format_efi_partition -a destination_disk partition_number -a source_partition size -d "allocate and format EFI Partition."
    not empty $destination_disk; or panic "must specify a destination disk!"
    not empty $partition_number; or panic "must specify a destination partition_number!"
    not empty $source_partition; and set copy_source true

    set destination_partition $destination_disk-part1
    set -e destination_disk #hide variable to prevent accidental writing of entire partition
    
    not empty $size; or begin
        set size "512M"
        echo "Setting EFI size to the default of $size"
    end

    confirm "EFI Formatting $destination_partition ($size). Sound good?"; or panic "Aborted EFI formatting"

    sgdisk -n1:1M:+512M -t1:$EFI_PARTITION_TYPE $target_disk; or panic "efi failed" #EFIz

    
    pv <$SRC_DISK-part1 >$DISK-part1
    parted --script $destination_disk name 1 EFI
    echo "EFI partition done."
end

function prep_new_disk -a destination_disk source_partition -d "wipe the disk, and put our partitions on it."
    not empty $destination_disk; or panic "must specify a destination disk!"
    not empty $source_partion; or echo "no source partition; won't blindly copy"
    confirm "about to destroy $destination_disk. We good?"; or panic "We weren't good."
    sgdisk --zap-all $destination_disk
    echo "zapped"

    set partition_number 1
    
    confirm "EFI partition on $partition_number?"; and begin
        format_efi_partition $destination_disk $partition_number $source_partition
        echo "EFI done."
        set partition_number (math $partition_number + 1)
    end
    
    confirm "boot pool on $partition_number?"; and begin
        sgdisk -n$partition_number:0:+2G -t$partition_number:$ZFS_PARTITION_TYPE $destination_disk or panic "bpool format failed" #boot pool
        set partition_number (math $partition_number + 1)
    end

    confirm "root pool on $partition_number?"; and begin
        sgdisk -n$partition_number:0:0 -t$partition_number:$ZFS_PARTITION_TYPE $destination_disk or panic "rpool format failed" #zfs main
    end
end

function _nooooo -a source_partition -a target_disk -d "Format the drive. Replace partition table"
    panic "don't run me"
    zpool import -N bpool

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
    not empty $source_disk; or panic "must specify a source disk!"    
    set source_partition $source_disk-part1
    set -e source_disk #hide variable to prevent accidental writing of entire disk

    echo "Source boot partition: $source_partition $source_disk"
    not empty $target_disk; or panic "must specify a target disk!"
    echo "Target: $target_disk"
    string match -q "*Force*" $target_disk; and panic "I think this Eternal's HD. If you're so sure it's not, then edit me."
    confirm "Wanna do this?"; or exit 1
    echo "Let's go!"
    prep_new_disk $target_disk $source_partition

end
status is-interactive; or main $argv
#zpool export bpool

#sudo apt install refind

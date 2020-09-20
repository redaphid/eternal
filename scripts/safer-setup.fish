#!/usr/bin/env fish

function do_it -a source_desk -a target_disk
    zpool import -N bpool

    sgdisk --zap-all $DISK #format
    sgdisk -n1:1M:+512M -t1:EF00 $DISK #EFI
    sgdisk -n2:0:+2G -t2:BE00 $DISK #boot pool
    sgdisk -n3:0:0 -t3:BF00 $DISK #zfs main

    pv <$SRC_DISK-part1 >$DISK-part1
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
end

function panic -a msg
    set_color red
    echo $argv 1>&2
    set_color normal
    exit 1
end

function main -a source_disk target_disk -d "Eternal-ify from source->target disk"
    string length -q $source_disk; or panic "must specify a source disk!"
    string length -q $target_disk; or panic "must specify a target disk!"
    string match -q "*Force*" $target_disk; and panic "I think this Eternal's HD. If you're so sure it's not, then edit me."

end
status is-interactive; or main $argv
#zpool export bpool

#sudo apt install refind

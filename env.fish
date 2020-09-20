#!/usr/bin/env fish
set -x SOURCE_DISK /dev/disk/by-id/nvme-Force_MP600_203182840001300527A3
set -x TARGET_DISK /dev/zvol/rpool/safe-vm
set -x SOURCE_DATASET charon/souls/laptop/rpool/ROOT/eternal

#!/usr/bin/env fish

function find_dataset
    zfs list -o name | grep -v NO_BACKUP | grep -v USERDATA | grep -v charon | grep -v IMAGES
end
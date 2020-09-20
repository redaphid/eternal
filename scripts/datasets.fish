#!/usr/bin/env fish

function find_dataset
    zfs list -t snapshot -o name | grep -v charon | grep -v nupool | grep "@eternity-begins-here"
end
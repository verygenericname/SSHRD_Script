#!/bin/bash
mount_apfs /dev/disk0s1s1 /mnt1
mount_apfs -R /dev/disk0s1s6 /mnt6
mount_apfs -R /dev/disk0s1s3 /mnt7
/usr/libexec/seputil --gigalocker-init
/usr/libexec/seputil --load /mnt6/$(cat /mnt6/active)/usr/standalone/firmware/sep-firmware.img4
mount_apfs /dev/disk0s1s2 /mnt2

#!/usr/bin/env bash

disks=$(ls /dev/nvme0*n1 | grep nvme | awk '{print $1}')
echo "Located disks $disks"
for i in $disks; do
	wipefs -fa $i && mkfs.ext4 $i
	mkdir -p /mnt/disks$i
	mount $i /mnt/disks$i
	if [[ $? -eq 0 ]]; then
		echo "Mounted $i"
		echo "$i   /mnt/disks$i       ext4    defaults,nofail   0   2" >/tmp/mnt_entry
		sh -c 'cat /tmp/mnt_entry  >> /etc/fstab'
	fi
done

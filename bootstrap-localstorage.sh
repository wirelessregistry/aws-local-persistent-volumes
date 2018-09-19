#!/usr/bin/env bash

disks=$(ls /dev/nvme*n1 | grep nvme | awk '{print $1}')
diskstripped=$(echo /dev/nvme*n1)
numdisks=$(echo /dev/nvme*n1 | wc -w)
echo "NVME Disks: $diskstripped"
if [ "$numdisks" -ge 2 ]
then
	export DEBIAN_FRONTEND=noninteractive
	apt-get -q -y install mdadm --no-install-recommends
  mdadm --create --verbose /dev/md0 --level=0 --name=LOCAL_STORAGE --raid-devices="$numdisks" "$diskstripped"
	sleep 15
	wipefs -fa /dev/md0 && mkfs.ext4 /dev/md0
	mkdir -p /mnt/disks/dev/md0
	mount /dev/md0 /mnt/disks/dev/md0
	echo "/dev/md0   /mnt/disks/dev/md0       ext4    defaults,nofail   0   2" >/tmp/mnt_entry
	sh -c 'cat /tmp/mnt_entry  >> /etc/fstab'
else
		wipefs -fa "$disks" && mkfs.ext4 "$disks"
		mkdir -p /mnt/disks"$disks"
		mount "$disks" /mnt/disks"$disks"
		echo "$disks   /mnt/disks$disks       ext4    defaults,nofail   0   2" >/tmp/mnt_entry
		sh -c 'cat /tmp/mnt_entry  >> /etc/fstab'
fi

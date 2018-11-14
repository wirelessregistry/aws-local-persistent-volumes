#!/usr/bin/env bash

diskstripped=$(lsblk -noheadings -ido NAME |tr '\n' ' ')
numdisks=$(lsblk -noheadings -ido NAME |wc -w)
echo "NVME Disks: $diskstripped"
if [ "$numdisks" -ge 3 ]
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
    for diskname in $diskstripped; do
    wipefs -fa "/dev/$diskname" && mkfs.ext4 "/dev/$diskname" || true
    mkdir -p /mnt/disks/dev/"$diskname"
    mount "/dev/$diskname" /mnt/disks/dev/"$diskname"
    echo "/dev/$diskname   /mnt/disks/dev/$diskname       ext4    defaults,nofail   0   2" >/tmp/mnt_entry
    sh -c 'cat /tmp/mnt_entry  >> /etc/fstab'
    done
fi

# Local storage (NVME) for Kubernetes 1.10+ on Amazon Web Services

## Overview

Local persistent volumes allows users to access local storage through the standard PVC interface in a simple and portable way. The persistent volume contains node affinity information that the system uses to schedule pods to the correct nodes.

Current documentation and example is provided by the Kubernetes team running local storage on Google Compute Engine. However, if you are looking to run an i3.x series instance on Amazon Web Services and utilize the fast IOPS of the NVME SSDs provided, documentation is lacking.

In this repository you will find example configuration and scripts.

# Caveats

Utilizing the local storage of an instance is not considered best practice with Kubernetes. Kubernetes attempts to schedule all pods in a stateful set with same, predictable resources. On Amazon Web Services this means that storage is by way of EBS volumes as they can be attached to pods running on instances without fear of over-scheduling the node or storage conflicts.

However, specific classes of software such as database systems benefit greatly from dedicated, fast IOPS storage. If it is known the scheduled pod will retain an exclusive claim over the local storage this process can be very effective. Example: Creating an autoscaling group of i3.8xlarge EC2 instances for a Cassandra cluster. Each instance would receive only one Cassandra node pod guaranteed by affinity settings.

## Requirements

- Kubernetes 1.10+ Cluster
- Amazon Web Services i3.x series instance types

# Process

- Kubernetes 1.10+ requires all local storage devices are appropriately formatted and mounted prior to use as a persistent volume. In order to do this automatically the script `bootstrap-localstorage.sh` must be injected into the instance metadata. Injection of script data and execution at bootup is outside the scope of this process but additional information can be found [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html).
- Smarter scheduling of the local storage by way of `storageclass-local-storage.yaml` should be created within your cluster. Prior to any PersistentVolumeClaims for created PersistentVolumes a StorageClass must be created with the volumeBindingMode set to “WaitForFirstConsumer”. Ex: `$ kubectl create -f storageclass-local-storage.yaml`
- Automation of local volume management within your cluster is handled by the [Storage Provisioner](https://github.com/kubernetes-incubator/external-storage/tree/master/local-volume). The included `daemonset-provisioner.yaml` configures the provisioner appropriately.<br /><br /> `$ kubectl create -f daemonset-provisioner.yaml`
- Once the provisioner is installed and local storage disks have been formatted and mounted, verify the persistent volumes are available for claim with `$ kubectl get pv`

# Sample Persistence for Local Storage for pods

```
persistence:
  enabled: true
  storageClass: "local-storage"
  accessMode: ReadWriteOnce
  size: 7021Gi
```

# Additional Notes

Amazon Web Services i3.x series above i3.2xlarge provide multiple NVME drives, not progressively larger drives. This means that the drives, assuming one large mount is desired for storage, must be configured in a RAID-0 configuration. The `bootstrap-localstorage.sh` assumes a Debian-based operating system and utilizes the mdadm tool for configuring a RAID-0. Modify the script for your operating system and RAID needs as required.

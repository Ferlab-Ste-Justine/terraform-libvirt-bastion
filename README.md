# About

This package is a terraform module to provision a bastion on kvm.

The package takes an public external ssh key to login to the bastion and an internal ssh key pair that will be setup on the bastion so that a user can login to other machines from the bastion.

The bastion provision docker as part of its cloud-init logic.

# Usage

## Variables

The module takes the following variables as input:

- **name**: Name of the bastion vm
- **vcpus**: Number of vcpus to assign to the bastion
- **memory**: Amount of memory to assign to the bastion in MiB
- **volume_id**: Id of the disk volume to attach to the vm
- **libvirt_network**: Parameters to connect to libvirt networks. Each entry has the following keys:
  - **network_id**: Id (ie, uuid) of the libvirt network to connect to (in which case **network_name** should be an empty string).
  - **network_name**: Name of the libvirt network to connect to (in which case **network_id** should be an empty string).
  - **ip**: Ip of interface connecting to the libvirt network.
  - **mac**: Mac address of interface connecting to the libvirt network.
  - **prefix_length**:  Length of the network prefix for the network the interface will be connected to. For a **192.168.1.0/24** for example, this would be **24**.
  - **gateway**: Ip of the network's gateway. Usually the gateway the first assignable address of a libvirt's network.
  - **dns_servers**: Dns servers to use. Usually the dns server is first assignable address of a libvirt's network.
- **macvtap_interfaces**: List of macvtap interfaces to connect the vm to if you opt for macvtap interfaces. Each entry in the list is a map with the following keys:
  - **interface**: Host network interface that you plan to connect your macvtap interface with.
  - **prefix_length**: Length of the network prefix for the network the interface will be connected to. For a **192.168.1.0/24** for example, this would be 24.
  - **ip**: Ip associated with the macvtap interface. 
  - **mac**: Mac address associated with the macvtap interface
  - **gateway**: Ip of the network's gateway for the network the interface will be connected to.
  - **dns_servers**: Dns servers for the network the interface will be connected to. If there aren't dns servers setup for the network your vm will connect to, the ip of external dns servers accessible accessible from the network will work as well.
- **cloud_init_volume_pool**: Name of the volume pool that will contain the cloud-init volume of the vm.
- **cloud_init_volume_name**: Name of the cloud-init volume that will be generated by the module for your vm. If left empty, it will default to ``<vm name>-cloud-init.iso``.
- **ssh_admin_user**: Username of the default sudo user in the image. Defaults to **ubuntu**.
- **admin_user_password**: Optional password for the default sudo user of the image. Note that this will not enable ssh password connections, but it will allow you to log into the vm from the host using the **virsh console** command.
- **ssh_admin_public_key**: Public part of the ssh key that will be used to login as the admin on the bastion
- **ssh_internal_private_key**: Private part of the ssh keypair that the bastion will use to ssh on instances
- **ssh_internal_public_key**: Public part of the ssh keypair that the bastion will use to ssh on instances
- **chrony**: Optional chrony configuration for when you need a more fine-grained ntp setup on your vm. It is an object with the following fields:
  - **enabled**: If set to false (the default), chrony will not be installed and the vm ntp settings will be left to default.
  - **servers**: List of ntp servers to sync from with each entry containing two properties, **url** and **options** (see: https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#server)
  - **pools**: A list of ntp server pools to sync from with each entry containing two properties, **url** and **options** (see: https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#pool)
  - **makestep**: An object containing remedial instructions if the clock of the vm is significantly out of sync at startup. It is an object containing two properties, **threshold** and **limit** (see: https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#makestep)
- **install_dependencies**: Whether cloud-init should install external dependencies (should be set to false if you already provide an image with the external dependencies built-in).

## Example

Here is an example of how the bastion module might be used:

```
data "local_file" "bastion_ssh_external_public_key" {
  filename = pathexpand("~/bastion-external/id_rsa.pub")
}

data "local_file" "bastion_ssh_internal_public_key" {
  filename = pathexpand("~/bastion-internal/id_rsa.pub")
}

data "local_file" "bastion_ssh_internal_private_key" {
  filename = pathexpand("~/bastion-internal/id_rsa")
}


resource "libvirt_volume" "bastion" {
  name             = "bastion"
  pool             = "bastion"
  //10 GiB
  size             = 10 * 1024 * 1024 * 1024
  base_volume_pool = "os"
  base_volume_name = "ubuntu"
  format = "qcow2"
}

module "bastion_alpha" {
  source = "git::https://github.com/Ferlab-Ste-Justine/kvm-bastion"
  name = "bastion"
  vcpus = 1
  memory = 4096
  volume_id = libvirt_volume.bastion.id
  libvirt_networks = [{
    network_name = "ferlab"
    network_id = ""
    ip = netaddr_address_ipv4.k8_bastion.0.address
    mac = netaddr_address_mac.k8_bastion.0.address
    gateway = local.params.network.gateway
    dns_servers = [local.params.network.dns]
    prefix_length = split("/", local.params.network.addresses).1
  }]
  cloud_init_volume_pool = "cloud-init-vols"
  ssh_internal_public_key = chomp(data.local_file.bastion_ssh_internal_public_key.content)
  ssh_internal_private_key = chomp(data.local_file.bastion_ssh_internal_private_key.content)
  ssh_external_public_key = chomp(data.local_file.bastion_ssh_external_public_key.content)
  admin_user_password = "yes"
}
```

For networking elaboration and gotcha, see the following which is the same as this project: https://github.com/Ferlab-Ste-Justine/kvm-etcd-server#example

terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.1"
    }
  }
}

provider "libvirt" {
 #uri = "qemu:///system"
 uri = "qemu+ssh://robin@192.168.1.95/system?sshauth=privkey&no_verify=1"
}

resource "libvirt_volume" "ubuntu-jammy-cloud-image" {
 name   = "ubuntu-jammy-qcow2"
 pool   = "default"
 source = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
 format = "qcow2"
}

resource "libvirt_volume" "ubuntu-image" {
  name           = "ubuntu-image"
  base_volume_id = libvirt_volume.ubuntu-jammy-cloud-image.id
  pool           = "default"
  size           = 10737418240
}

resource "libvirt_cloudinit_disk" "cloud-config" {
  name           = "cloud-config.iso"
  user_data      = templatefile("${path.module}/cloud-config.yml", {
  })
  pool           = "default"
}

resource "libvirt_domain" "ubuntu" {
 name   = "ubuntu"
 description = "Ubuntu 22.04"
 memory = "2048"
 #machine = "pc-q35-6.2"
 xml {
   xslt = file("machine.xsl")
 }
 vcpu = 2
 qemu_agent = true

 cloudinit = libvirt_cloudinit_disk.cloud-config.id

 network_interface {
  macvtap = "enp108s0"
  wait_for_lease = true
 }

 cpu {
  mode = "host-passthrough"
 }

 console {
   type        = "pty"
   target_port = "0"
   target_type = "serial"
 }

 console {
   type        = "pty"
   target_type = "virtio"
   target_port = "1"
 }

 disk {
   volume_id = libvirt_volume.ubuntu-image.id
 }

 graphics {
   type        = "spice"
   listen_type = "address"
   autoport    = "true"
 }
}

output "ip" {
  value = libvirt_domain.ubuntu.*.network_interface.0.addresses
}

#output "ips" {
#  value = libvirt_domain.ubuntu.network_interface[0].addresses[0]
#}

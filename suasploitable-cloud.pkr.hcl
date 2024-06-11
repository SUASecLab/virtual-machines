variable "ssh_password" {
  type    = string
  default = "vagrant"
}

# Some sources:
# https://github.com/multani/packer-qemu-debian/tree/master

source "qemu" "suasploitable-cloud" {
  iso_url          = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso"
  iso_checksum     = "013f5b44670d81280b5b1bc02455842b250df2f0c6763398feb69af1a805a14f"
  output_directory = "build-suasploitable-cloud"
  shutdown_command = "echo '${var.ssh_password}'  | sudo -S /sbin/shutdown -hP now"
  disk_size        = "40G"
  format           = "qcow2"
  cpus             = "4"
  memory           = "4096"
  accelerator      = "kvm"
  http_directory   = "http"
  http_port_min    = "9000"
  http_port_max    = "9010"
  ssh_username     = "vagrant"
  ssh_password     = "${var.ssh_password}"
  ssh_timeout      = "20m"
  host_port_min    = "2000"
  host_port_max    = "2010"
  vm_name          = "suasploitable_cloud.qcow2"
  net_device       = "virtio-net"
  disk_interface   = "virtio"
  boot_wait        = "5s"
  headless         = "true"
  boot_command = [
    "<down><tab>",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/suasploitable-basic-preseed.cfg ",
    "language=en locale=de_DE.UTF-8 ",
    "country=DE keymap=de ",
    "hostname=debian domain=example.com ",
  "<enter><wait>"]
}

# Necessary:
# https://askubuntu.com/questions/1309029/qemu-display-gtk-and-display-sdl-not-available-ubuntu-20-04-1-lts

build {
  sources = ["source.qemu.suasploitable-cloud"]

  # Installation scripts
  provisioner "file" {
    sources = [
      "scripts/programs/docker.sh",
      "scripts/programs/suasploitable/cloud/seafile.sh",
      "scripts/programs/suasploitable/lamp.sh",
      "scripts/programs/suasploitable/lemp.sh",
      "scripts/programs/suasploitable/cloud/nextcloud.sh",
      "files/nextcloud_apache.conf",
      "files/nextcloud_nginx.conf",
      "files/seafile_compose.yml"
    ]
    destination = "/tmp/"
  }

  # Set hostname
  provisioner "shell" {
    execute_command = "echo 'packer' | sudo -S env {{ .Vars }} {{ .Path }}"
    inline = ["hostnamectl set-hostname cloud.suaseclab.de"]
  }

  # Install and set up programs
  provisioner "shell" {
    execute_command = "echo 'packer' | sudo -S env {{ .Vars }} {{ .Path }}"
    scripts = [
      # Install programs first
      "scripts/programs/suasploitable/environment.sh",

      # Install cloud: Either SeaFile or Nextcloud. NC with either LAMP or LEMP stack
      "scripts/programs/suasploitable/cloud/install.sh",

      # Set up main system
      "scripts/autostart.sh",
      "scripts/programs/suasploitable/ssh.sh",
      
      # Fix permissions (must be called last)
      "scripts/permissions.sh"
    ]
  }
}

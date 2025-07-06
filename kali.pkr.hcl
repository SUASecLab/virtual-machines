variable "ssh_password" {
  type    = string
  default = "TH3P455W0RD"
}

# Some sources:
# https://github.com/multani/packer-qemu-debian/tree/master

variable "output_directory" {
  type    = string
  default = "build-kali"
}

source "qemu" "kali" {
  iso_url          = "https://cdimage.kali.org/kali-2025.2/kali-linux-2025.2-installer-amd64.iso"
  iso_checksum     = "5723d46414b45575aa8e199740bbfde49e5b2501715ea999f0573e94d61e39d3"
  output_directory = "${var.output_directory}"
  shutdown_command = "echo '${var.ssh_password}'  | sudo -S /sbin/shutdown -hP now"
  disk_size        = "40G"
  format           = "qcow2"
  cpus             = "4"
  memory           = "4096"
  accelerator      = "kvm"
  http_directory   = "http"
  http_port_min    = "9000"
  http_port_max    = "9010"
  ssh_username     = "laboratory"
  ssh_password     = "${var.ssh_password}"
  ssh_timeout      = "40m"
  host_port_min    = "2000"
  host_port_max    = "2010"
  vm_name          = "kali_base.qcow2"
  net_device       = "virtio-net"
  disk_interface   = "virtio"
  boot_wait        = "5s"
  headless         = "true"
  boot_command = [
    "<down><tab>",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/kali-preseed.cfg ",
    "language=en locale=de_DE.UTF-8 ",
    "country=DE keymap=de ",
    "hostname=laboratory domain=example.com ",
  "<enter><wait>"]
}

# Necessary:
# https://askubuntu.com/questions/1309029/qemu-display-gtk-and-display-sdl-not-available-ubuntu-20-04-1-lts

build {
  sources = ["source.qemu.kali"]

  ## Copy files

  # Configuration file for autologin
  provisioner "file" {
    sources      = [
      "files/lightdm.conf"
    ]
    destination = "/tmp/"
  }

  # Set up automatic login
  provisioner "shell" {
    execute_command = "echo 'packer' | sudo -S env {{ .Vars }} {{ .Path }}"
    inline = [
      "mv /tmp/lightdm.conf /etc/lightdm/lightdm.conf"
    ]
  }

  # SUASecLab networking
  provisioner "file" {
    sources = [
      "files/ca/suasploitable_ca.crt",
      "files/kali/firefox_policies.json",
      "files/kali/kali_environment.sh",
      "files/kali/network.sh",
      "files/kali/tcp_client.py"
    ]
    destination = "/tmp/"
  }

  # Set up system
  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    execute_command = "echo 'packer' | sudo -S env {{ .Vars }} {{ .Path }}"
    scripts = [
      # Set up main system
      "scripts/autostart.sh",
      "scripts/fs_share.sh",

      # Setup kali environment
      "scripts/environments/kali.sh",

      # Create desktop entries
      "scripts/desktops/desktop-exercises.sh",

      # Hide CTF flags
      "scripts/environments/kali_ctf.sh",

      # Fix permissions (must be called last)
      "scripts/permissions.sh"
    ]
  }
  
  # Save flags
  provisioner "file" {
    source = "/tmp/flags.txt"
    destination = "${var.output_directory}/"
    direction   = "download"
  }
}

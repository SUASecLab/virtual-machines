variable "ssh_password" {
  type    = string
  default = "TH3P455W0RD"
}

# Some sources:
# https://github.com/multani/packer-qemu-debian/tree/master

source "qemu" "heaven-base" {
  iso_url          = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso"
  iso_checksum     = "013f5b44670d81280b5b1bc02455842b250df2f0c6763398feb69af1a805a14f"
  output_directory = "build-heaven"
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
  ssh_timeout      = "20m"
  host_port_min    = "2000"
  host_port_max    = "2010"
  vm_name          = "heaven_base.qcow2"
  net_device       = "virtio-net"
  disk_interface   = "virtio"
  boot_wait        = "5s"
  headless         = "true"
  boot_command = [
    "<down><tab>",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/debian-preseed.cfg ",
    "language=en locale=de_DE.UTF-8 ",
    "country=DE keymap=de ",
    "hostname=debian domain=example.com ",
  "<enter><wait>"]
}

# Necessary:
# https://askubuntu.com/questions/1309029/qemu-display-gtk-and-display-sdl-not-available-ubuntu-20-04-1-lts

build {
  sources = ["source.qemu.heaven-base"]

  ## Copy files

  # Programs
  provisioner "file" {
    sources = [
      "dependencies/openjdk-17+35_linux-x64_bin.tar.gz"
    ]
    destination = "/tmp/"
  }

  # Configuration file for autologin
  provisioner "file" {
    source      = "files/lightdm.conf"
    destination = "/tmp/"
  }

  # Set up automatic login
  provisioner "shell" {
    execute_command = "echo 'packer' | sudo -S env {{ .Vars }} {{ .Path }}"
    inline = [
      "mv /tmp/lightdm.conf /etc/lightdm/lightdm.conf"
    ]
  }

  # Install and set up development environments
  provisioner "shell" {
    execute_command = "echo 'packer' | sudo -S env {{ .Vars }} {{ .Path }}"
    scripts = [
      # Install programs first
      "scripts/programs/programs-basic.sh",
      "scripts/programs/programs-network.sh",
      "scripts/programs/bluefish.sh",
      "scripts/programs/cc-amd64.sh",
      "scripts/programs/docker.sh",
      "scripts/programs/geany.sh",
      "scripts/programs/java-17.sh",
      "scripts/programs/python.sh",
      "scripts/programs/raid.sh",
      "scripts/programs/tex.sh",

      # Set up main system
      "scripts/environments/webdevelopment.sh",
      "scripts/autostart.sh",
      "scripts/fs_share.sh",
      "scripts/startmenu.sh",

      # Create desktop entries
      "scripts/desktops/desktop-exercises.sh",
      "scripts/desktops/desktop-filezilla.sh",
      "scripts/desktops/desktop-heaven-base.sh",
      "scripts/desktops/desktop-heaven-extended.sh",
      "scripts/desktops/desktop-shell.sh",

      # Fix permissions (must be called last)
      "scripts/permissions.sh"
    ]
  }
}

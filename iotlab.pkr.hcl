variable "ssh_password" {
  type    = string
  default = "TH3P455W0RD"
}

# Some sources:
# https://github.com/multani/packer-qemu-debian/tree/master

source "qemu" "iot-base" {
  iso_url          = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.11.0-amd64-netinst.iso"
  iso_checksum     = "30ca12a15cae6a1033e03ad59eb7f66a6d5a258dcf27acd115c2bd42d22640e8"
  output_directory = "build-iotlab"
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
  vm_name          = "iot_base.qcow2"
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
  sources = ["source.qemu.iot-base"]

  ## Copy files

  # Programs
  provisioner "file" {
    sources = [
      "dependencies/openjdk-17+35_linux-x64_bin.tar.gz",
      "dependencies/apache-ant-1.10.14-bin.tar.gz",
      "dependencies/gcc-arm-none-eabi-9-2020-q2-update-x86_64-linux.tar.bz2",
      "dependencies/mspgcc-4.7.2-compiled.tar.bz2"
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

  # Install and set up contiki development environment
  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    execute_command = "echo 'packer' | sudo -S env {{ .Vars }} {{ .Path }}"
    scripts = [
      # Install programs first
      "scripts/programs/programs-basic.sh",
      "scripts/programs/programs-network.sh",
      "scripts/programs/java-17.sh",
      "scripts/programs/ant.sh",

      # Set up main system
      "scripts/environments/contiki.sh",
      "scripts/autostart.sh",
      "scripts/fs_share.sh",
      "scripts/startmenu.sh",

      # Create desktop entries
      "scripts/desktops/desktop-contiki.sh",
      "scripts/desktops/desktop-exercises.sh",
      "scripts/desktops/desktop-resolution.sh",
      "scripts/desktops/desktop-filezilla.sh",
      "scripts/desktops/desktop-shell.sh",

      # Fix permissions (must be called last)
      "scripts/permissions.sh"
    ]
  }
}

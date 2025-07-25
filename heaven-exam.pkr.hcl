variable "ssh_password" {
  type    = string
  default = "TH3P455W0RD"
}

# Some sources:
# https://github.com/multani/packer-qemu-debian/tree/master

source "qemu" "heaven-exam" {
  iso_url          = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.11.0-amd64-netinst.iso"
  iso_checksum     = "30ca12a15cae6a1033e03ad59eb7f66a6d5a258dcf27acd115c2bd42d22640e8"
  output_directory = "build-heaven-exam"
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
  vm_name          = "heaven_exam.qcow2"
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
  sources = ["source.qemu.heaven-exam"]

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

  # Configuration file for autologin
  provisioner "file" {
    source      = "files/pushExam.sh"
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
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    execute_command = "echo 'packer' | sudo -S env {{ .Vars }} {{ .Path }}"
    scripts = [
      # Install programs first
      "scripts/programs/programs-basic.sh",
      "scripts/programs/cc-amd64.sh",
      "scripts/programs/geany.sh",
      "scripts/programs/java-17.sh",
      "scripts/programs/python.sh",
      "scripts/programs/raid.sh",
      "scripts/programs/exam.sh",

      # Set up main system
      "scripts/autostart.sh",
      "scripts/startmenu.sh",

      # Create desktop entries
      "scripts/desktops/desktop-heaven-base.sh",
      "scripts/desktops/desktop-shell.sh",
      "scripts/desktops/desktop-resolution.sh",

      # Finalise
      "scripts/environments/exam.sh",

      # Fix permissions (must be called last)
      "scripts/permissions.sh"
    ]
  }
}

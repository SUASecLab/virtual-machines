variable "ssh_password" {
  type    = string
  default = "TH3P455W0RD"
}

variable "output_directory" {
  type    = string
  default = "CMS_OUTPUT_DIR"
}

# Some sources:
# https://github.com/multani/packer-qemu-debian/tree/master

source "qemu" "suasploitable-cms" {
  iso_url          = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.11.0-amd64-netinst.iso"
  iso_checksum     = "30ca12a15cae6a1033e03ad59eb7f66a6d5a258dcf27acd115c2bd42d22640e8"
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
  ssh_username     = "vagrant"
  ssh_password     = "${var.ssh_password}"
  ssh_timeout      = "40m"
  host_port_min    = "2000"
  host_port_max    = "2010"
  vm_name          = "suasploitable_cms.qcow2"
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
  sources = ["source.qemu.suasploitable-cms"]

  # Installation scripts
  provisioner "file" {
    sources = [
      # Scripts called by other scripts or python
      "scripts/programs/suasploitable/data_center/python/cms.py",
      "scripts/programs/suasploitable/data_center/python/configuration.py",
      "scripts/programs/suasploitable/data_center/python/environment.py",
      "scripts/programs/suasploitable/data_center/python/gacha.py",
      "scripts/programs/suasploitable/data_center/python/identities.py",
      "scripts/programs/suasploitable/data_center/python/mail.py",
      "scripts/programs/suasploitable/data_center/python/password.py",
      "scripts/programs/suasploitable/data_center/python/sendmail.py",
      "scripts/programs/suasploitable/data_center/python/webserver.py",

      # Configuration files for Drupal
      "files/drupal/drupal_apache.conf",
      "files/drupal/drupal_apache_tls.conf",
      "files/drupal/drupal_nginx.conf",
      "files/drupal/drupal_nginx_tls.conf",

      # Configuration files for WordPress
      "files/wp/wp_apache.conf",
      "files/wp/wp_apache_tls.conf",
      "files/wp/wp_nginx.conf",
      "files/wp/wp_nginx_tls.conf",

      # TLS certificates
      "files/ca/suaseclab.de.2048.crt",
      "files/ca/suaseclab.de.2048.key",
      "files/ca/suaseclab.de.4096.crt",
      "files/ca/suaseclab.de.4096.key",
      "files/ca/suasploitable_ca.crt",

      # Joker
      "files/joker.sh",
      "files/ssh-betterdefaultpasslist.txt",

      # Password list
      "files/500-worst-passwords.txt"
    ]
    destination = "/tmp/"
  }

  # Set hostname
  provisioner "shell" {
    execute_command = "echo 'packer' | sudo -S env {{ .Vars }} {{ .Path }}"
    inline = ["hostnamectl set-hostname suaseclab.de"]
  }

  # Install and set up programs
  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
      "SSH_PASSWORD=${var.ssh_password}"
    ]
    execute_command = "echo 'packer' | sudo -S env {{ .Vars }} {{ .Path }}"
    scripts = [
      # Set up main system
      "scripts/autostart.sh",
      "scripts/programs/suasploitable/environment.sh",

      # Install CMS
      "scripts/programs/suasploitable/data_center/bash/cms.sh",
      
      # Fix permissions (must be called last)
      "scripts/permissions.sh",
    ]
  }

  # Save configuration and flags
  provisioner "file" {
    sources = [
      "/tmp/configuration.json",
      "/tmp/install_script.sh",
      "/tmp/flags.txt"
    ]
    destination = "${var.output_directory}/"
    direction   = "download"
  }
}

packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = ">= 1.1.0"
    }
  }
}

# =======================
#        Variables
# =======================
variable "iso_url" {
  type    = string
  default = "/home/romain1/Downloads/Win10_22H2_English_x64v1.iso"
}

variable "iso_checksum" {
  type    = string
  default = "none" # mets la vraie somme si tu veux
}

variable "vm_name" {
  type    = string
  default = "windows_pwsh_lab.qcow2"
}

variable "disk_size" {
  type    = string
  default = "40G"
}

variable "cpus" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  default = 4096
}

variable "admin_password" {
  type      = string
  sensitive = true
  default   = "P@ssw0rd123!"
}

variable "vnc_port" {
  type    = number
  default = 5912
}

# =======================
#        Source QEMU
# =======================
source "qemu" "winlab" {
  # ISO
  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum

  # Sortie disque
  output_directory = "build"
  vm_name          = var.vm_name
  format           = "qcow2"
  disk_size        = var.disk_size
  disk_interface   = "ide"     # simple, pas de pilotes VirtIO
  accelerator      = "kvm"

  # Matériel
  cpus   = var.cpus
  memory = var.memory

  # Réseau: NAT par défaut (pas de qemuargs foireux)
  net_device = "e1000"

  # VNC
  headless         = true
  display          = "none"
  vnc_bind_address = "127.0.0.1"
  vnc_port_min     = var.vnc_port
  vnc_port_max     = var.vnc_port

  # Lecteur A:\ (floppy) -> ton XML + tout le dossier script/
  floppy_files = ["http/Autounattend.xml"]
  floppy_dirs  = ["scripts/pwsh-lab"]

  # Communicator Windows
  communicator   = "winrm"
  winrm_username = "Administrator"
  winrm_password = var.admin_password
  winrm_insecure = true
  winrm_timeout  = "2h"

  boot_wait = "5s"
}

# =======================
#          Build
# =======================
build {
  name    = "windows-powershell-lab"
  sources = ["source.qemu.winlab"]

  # Petit test côté invité quand WinRM répond
  provisioner "powershell" {
    inline = [
      "Write-Host 'WinRM OK depuis Packer'; New-Item -Path C:\\ -Name __packer_ok.txt -ItemType File -Force | Out-Null"
    ]
  }
}

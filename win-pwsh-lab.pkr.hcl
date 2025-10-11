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
# change the path to your ISO file
  default = "/home/romain1/Downloads/Win10_22H2_English_x64v1.iso"
}

variable "iso_checksum" {
  type    = string
# you can let the checksum to default ="none" or the true one
  default = "none" 
}

variable "vm_name" {
  type    = string
  default = "windows_pwsh_lab.qcow2"
}

# you can change the variables to yours 
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

  # Disk Output
  output_directory = "build"
  vm_name          = var.vm_name
  format           = "qcow2"
  disk_size        = var.disk_size
  disk_interface   = "ide"
  accelerator      = "kvm"

  # Materiel
  cpus   = var.cpus
  memory = var.memory

  # Network :default = "NAT"
  net_device = "e1000"

  # VNC
  headless         = true
  display          = "none"
  vnc_bind_address = "127.0.0.1"
  vnc_port_min     = var.vnc_port
  vnc_port_max     = var.vnc_port

  # Disk  A:\ (floppy) ->  XML (http/Autounattend.xml) + directory (script/pwsh-lab)
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

  # check  WinRM répond
  provisioner "powershell" {
    inline = [
      "Write-Host 'WinRM OK from  Packer'; New-Item -Path C:\\ -Name __packer_ok.txt -ItemType File -Force | Out-Null"
    ]
  }
}

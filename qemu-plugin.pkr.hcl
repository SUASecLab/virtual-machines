# Load QEMU plugin
# https://github.com/hashicorp/packer-plugin-qemu
# https://developer.hashicorp.com/packer/integrations/hashicorp/qemu/latest/components/builder/qemu

packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.10"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

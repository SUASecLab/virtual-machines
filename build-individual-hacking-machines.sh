#!/bin/bash

if [ $# -le 7 ]; then
	cat << EOF
Parameters:
1. Main directory
2. Running number
3. VNC port (kali)
4. VNC port (cloud)
5. VNC port (cms)
6. VNC port (devbox)
7. VNC password
8. Shared directory (kali)
EOF
	exit 0
fi

# Change output dir paths
BASIC_DIR=${1}/basic
CMS_DIR=${1}/cms
CLOUD_DIR=${1}/cloud
DEVBOX_DIR=${1}/devbox
KALI_DIR=${1}/kali

sed -i "s|CMS_OUTPUT_DIR|$CMS_DIR|g" suasploitable-cms.pkr.hcl
sed -i "s|CLOUD_OUTPUT_DIR|$CLOUD_DIR|g" suasploitable-cloud.pkr.hcl
sed -i "s|DEVBOX_OUTPUT_DIR|$DEVBOX_DIR|g" suasploitable-devbox.pkr.hcl

# Build kali if not existant
if [ ! -f  build-kali/kali_base.qcow2 ]; then
    echo "Building Kali VM"
    packer build kali.pkr.hcl
else
    echo "Copying Kali VM"
    mkdir -p $KALI_DIR
    cp build-kali/* $KALI_DIR -r
fi

# Build basic if not existant
if [ ! -f  build-suasploitable-basic/suasploitable_basic.qcow2 ]; then
    echo "Building Basic VM"
    packer suasploitable-basic.pkr.hcl
else
    echo "Copying Basic VM"
    mkdir -p $BASIC_DIR
    cp build-suasploitable-basic/* $BASIC_DIR -r
fi

# Build cloud machine
packer build suasploitable-cloud.pkr.hcl

# Build cms
packer build suasploitable-cms.pkr.hcl

# Build devbox
packer build suasploitable-devbox.pkr.hcl

echo "Built machines"

# Create network
cat > ${1}/network.xml << EOF
<network>
  <name>hacking${2}</name>
  <uuid>eec6f237-d105-4833-a72b-7ae82bf180${2}</uuid>
  <bridge name="virbr${2}" stp="on" delay="0"/>
  <mac address="52:54:00:9c:b3:${2}"/>
  <domain name="hacking${2}"/>
  <ip address="192.168.2${2}.1" netmask="255.255.255.0">
    <dhcp>
      <range start="192.168.2${2}.128" end="192.168.2${2}.254"/>
    </dhcp>
  </ip>
</network>
EOF

sudo virsh net-create ${1}/network.xml
echo "Created network"

# Create disk images
CUR_DIR=$(pwd)

cd $BASIC_DIR
qemu-img create -f qcow2 -F qcow2 -b suasploitable_basic.qcow2 suasploitable_basic.disk.qcow2
cd $BASIC_DIR

cd $CLOUD_DIR
qemu-img create -f qcow2 -F qcow2 -b suasploitable_cloud.qcow2 suasploitable_cloud.disk.qcow2
cd $CUR_DIR

cd $CMS_DIR
qemu-img create -f qcow2 -F qcow2 -b suasploitable_cms.qcow2 suasploitable_cms.disk.qcow2
cd $CUR_DIR

cd $DEVBOX_DIR
qemu-img create -f qcow2 -F qcow2 -b suasploitable_devbox.qcow2 suasploitable_devbox.disk.qcow2
cd $CUR_DIR

cd $KALI_DIR
qemu-img create -f qcow2 -F qcow2 -b kali_base.qcow2 kali_base.disk.qcow2
cd $CUR_DIR

# Create basic machine
cat > $BASIC_DIR/vm.xml << EOF
<domain type="kvm">
  <name>suasploitable${2}-basic</name>
  <uuid>d59e6e2b-86ed-42b5-9556-761a281270${2}</uuid>
  <memory unit="KiB">2097152</memory>
  <currentMemory unit="KiB">2097152</currentMemory>
  <vcpu placement="static">1</vcpu>
  <os>
    <type arch="x86_64" machine="pc-q35-9.1">hvm</type>
    <boot dev="hd"/>
    <bootmenu enable="no"/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <cpu mode="host-passthrough" check="none" migratable="on"/>
  <clock offset="utc"/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type="file" device="disk">
      <driver name="qemu" type="qcow2"/>
      <source file="$BASIC_DIR/suasploitable_basic.disk.qcow2"/>
      <target dev="vda" bus="virtio"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x05" function="0x0"/>
    </disk>
    <controller type="pci" index="0" model="pcie-root"/>
    <controller type="pci" index="1" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="1" port="0x10"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x0" multifunction="on"/>
    </controller>
    <controller type="pci" index="2" model="pcie-to-pci-bridge">
      <model name="pcie-pci-bridge"/>
      <address type="pci" domain="0x0000" bus="0x01" slot="0x00" function="0x0"/>
    </controller>
    <controller type="pci" index="3" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="3"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x01" function="0x0"/>
    </controller>
    <controller type="pci" index="4" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="4"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x02" function="0x0"/>
    </controller>
    <controller type="pci" index="5" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="5"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x03" function="0x0"/>
    </controller>
    <controller type="pci" index="6" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="6"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x04" function="0x0"/>
    </controller>
    <controller type="pci" index="7" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="7"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x05" function="0x0"/>
    </controller>
    <controller type="pci" index="8" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="8"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x06" function="0x0"/>
    </controller>
    <controller type="pci" index="9" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="9" port="0x11"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x1"/>
    </controller>
    <controller type="pci" index="10" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="10" port="0x12"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x2"/>
    </controller>
    <controller type="usb" index="0" model="qemu-xhci" ports="15">
      <address type="pci" domain="0x0000" bus="0x09" slot="0x00" function="0x0"/>
    </controller>
    <controller type="sata" index="0">
      <address type="pci" domain="0x0000" bus="0x00" slot="0x1f" function="0x2"/>
    </controller>
    <interface type="network">
      <mac address="52:54:00:37:10:${2}"/>
      <source network="hacking${2}"/>
      <model type="virtio"/>
      <driver iommu="off"/>
      <link state="up"/>
      <alias name="ua-net-0"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x04" function="0x0"/>
    </interface>
    <serial type="pty">
      <target type="isa-serial" port="0">
        <model name="isa-serial"/>
      </target>
    </serial>
    <console type="pty">
      <target type="serial" port="0"/>
    </console>
    <input type="mouse" bus="ps2"/>
    <input type="keyboard" bus="ps2"/>
    <graphics type="vnc" port="-1" autoport="yes">
      <listen type="address"/>
    </graphics>
    <video>
      <model type="cirrus" vram="16384" heads="1" primary="yes"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x01" function="0x0"/>
    </video>
    <memballoon model="virtio">
      <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x0"/>
    </memballoon>
  </devices>
</domain>
EOF

# Create cloud machine
cat > $CLOUD_DIR/vm.xml << EOF
<domain type="kvm">
  <name>suasploitable${2}-cloud</name>
  <uuid>d59e6e2b-86ed-42b5-9556-7614286271${2}</uuid>
  <memory unit="KiB">2097152</memory>
  <currentMemory unit="KiB">2097152</currentMemory>
  <vcpu placement="static">1</vcpu>
  <os>
    <type arch="x86_64" machine="pc-q35-9.1">hvm</type>
    <boot dev="hd"/>
    <bootmenu enable="no"/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <cpu mode="host-passthrough" check="none" migratable="on"/>
  <clock offset="utc"/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type="file" device="disk">
      <driver name="qemu" type="qcow2"/>
      <source file="$CLOUD_DIR/suasploitable_cloud.disk.qcow2"/>
      <target dev="vda" bus="virtio"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x05" function="0x0"/>
    </disk>
    <controller type="pci" index="0" model="pcie-root"/>
    <controller type="pci" index="1" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="1" port="0x10"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x0" multifunction="on"/>
    </controller>
    <controller type="pci" index="2" model="pcie-to-pci-bridge">
      <model name="pcie-pci-bridge"/>
      <address type="pci" domain="0x0000" bus="0x01" slot="0x00" function="0x0"/>
    </controller>
    <controller type="pci" index="3" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="3"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x01" function="0x0"/>
    </controller>
    <controller type="pci" index="4" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="4"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x02" function="0x0"/>
    </controller>
    <controller type="pci" index="5" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="5"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x03" function="0x0"/>
    </controller>
    <controller type="pci" index="6" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="6"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x04" function="0x0"/>
    </controller>
    <controller type="pci" index="7" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="7"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x05" function="0x0"/>
    </controller>
    <controller type="pci" index="8" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="8"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x06" function="0x0"/>
    </controller>
    <controller type="pci" index="9" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="9" port="0x11"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x1"/>
    </controller>
    <controller type="pci" index="10" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="10" port="0x12"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x2"/>
    </controller>
    <controller type="usb" index="0" model="qemu-xhci" ports="15">
      <address type="pci" domain="0x0000" bus="0x09" slot="0x00" function="0x0"/>
    </controller>
    <controller type="sata" index="0">
      <address type="pci" domain="0x0000" bus="0x00" slot="0x1f" function="0x2"/>
    </controller>
    <interface type="network">COUD_DIR
      <mac address="52:54:00:2a:1a:${2}"/>
      <source network="hacking${2}"/>
      <model type="virtio"/>
      <driver iommu="off"/>
      <link state="up"/>
      <alias name="ua-net-0"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x04" function="0x0"/>
    </interface>
    <serial type="pty">
      <target type="isa-serial" port="0">
        <model name="isa-serial"/>
      </target>
    </serial>
    <console type="pty">
      <target type="serial" port="0"/>
    </console>
    <input type="mouse" bus="ps2"/>
    <input type="keyboard" bus="ps2"/>
    <graphics type="vnc" port="${4}" autoport="no" listen="0.0.0.0" passwd="${7}">
      <listen type="address" address="0.0.0.0"/>
    </graphics>
    <video>
      <model type="cirrus" vram="16384" heads="1" primary="yes"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x01" function="0x0"/>
    </video>
    <memballoon model="virtio">
      <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x0"/>
    </memballoon>
  </devices>
</domain>
EOF

# Create CMS machine
cat > $CMS_DIR/vm.xml << EOF
<domain type="kvm">
  <name>suasploitable${2}-cms</name>
  <uuid>d59e6e2b-86ed-42b5-9576-7614286272${2}</uuid>
  <memory unit="KiB">2097152</memory>
  <currentMemory unit="KiB">2097152</currentMemory>
  <vcpu placement="static">1</vcpu>
  <os>
    <type arch="x86_64" machine="pc-q35-9.1">hvm</type>
    <boot dev="hd"/>
    <bootmenu enable="no"/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <cpu mode="host-passthrough" check="none" migratable="on"/>
  <clock offset="utc"/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type="file" device="disk">
      <driver name="qemu" type="qcow2"/>
      <source file="$CMS_DIR/suasploitable_cms.disk.qcow2"/>
      <target dev="vda" bus="virtio"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x05" function="0x0"/>
    </disk>
    <controller type="pci" index="0" model="pcie-root"/>
    <controller type="pci" index="1" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="1" port="0x10"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x0" multifunction="on"/>
    </controller>
    <controller type="pci" index="2" model="pcie-to-pci-bridge">
      <model name="pcie-pci-bridge"/>
      <address type="pci" domain="0x0000" bus="0x01" slot="0x00" function="0x0"/>
    </controller>
    <controller type="pci" index="3" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="3"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x01" function="0x0"/>
    </controller>
    <controller type="pci" index="4" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="4"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x02" function="0x0"/>
    </controller>
    <controller type="pci" index="5" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="5"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x03" function="0x0"/>
    </controller>
    <controller type="pci" index="6" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="6"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x04" function="0x0"/>
    </controller>
    <controller type="pci" index="7" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="7"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x05" function="0x0"/>
    </controller>
    <controller type="pci" index="8" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="8"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x06" function="0x0"/>
    </controller>
    <controller type="pci" index="9" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="9" port="0x11"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x1"/>
    </controller>
    <controller type="pci" index="10" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="10" port="0x12"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x2"/>
    </controller>
    <controller type="usb" index="0" model="qemu-xhci" ports="15">
      <address type="pci" domain="0x0000" bus="0x09" slot="0x00" function="0x0"/>
    </controller>
    <controller type="sata" index="0">
      <address type="pci" domain="0x0000" bus="0x00" slot="0x1f" function="0x2"/>
    </controller>
    <interface type="network">
      <mac address="52:54:00:2b:1b:${2}"/>
      <source network="hacking${2}"/>
      <model type="virtio"/>
      <driver iommu="off"/>
      <link state="up"/>
      <alias name="ua-net-0"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x04" function="0x0"/>
    </interface>
    <serial type="pty">
      <target type="isa-serial" port="0">
        <model name="isa-serial"/>
      </target>
    </serial>
    <console type="pty">
      <target type="serial" port="0"/>
    </console>
    <input type="mouse" bus="ps2"/>
    <input type="keyboard" bus="ps2"/>
    <graphics type="vnc" port="${5}" autoport="no" listen="0.0.0.0" passwd="${7}">
      <listen type="address" address="0.0.0.0"/>
    </graphics>
    <video>
      <model type="cirrus" vram="16384" heads="1" primary="yes"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x01" function="0x0"/>
    </video>
    <memballoon model="virtio">
      <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x0"/>
    </memballoon>
  </devices>
</domain>
EOF

# Create devbox machine
cat > $DEVBOX_DIR/vm.xml << EOF
<domain type="kvm">
  <name>suasploitable${2}-devbox</name>
  <uuid>d59e6e2b-54ed-42b5-9556-761a281272${2}</uuid>
  <memory unit="KiB">8388608</memory>
  <currentMemory unit="KiB">8388608</currentMemory>
  <vcpu placement="static">1</vcpu>
  <os>
    <type arch="x86_64" machine="pc-q35-9.1">hvm</type>
    <boot dev="hd"/>
    <bootmenu enable="no"/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <cpu mode="host-passthrough" check="none" migratable="on"/>
  <clock offset="utc"/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type="file" device="disk">
      <driver name="qemu" type="qcow2"/>
      <source file="$DEVBOX_DIR/suasploitable_devbox.disk.qcow2"/>
      <target dev="vda" bus="virtio"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x05" function="0x0"/>
    </disk>
    <controller type="pci" index="0" model="pcie-root"/>
    <controller type="pci" index="1" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="1" port="0x10"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x0" multifunction="on"/>
    </controller>
    <controller type="pci" index="2" model="pcie-to-pci-bridge">
      <model name="pcie-pci-bridge"/>
      <address type="pci" domain="0x0000" bus="0x01" slot="0x00" function="0x0"/>
    </controller>
    <controller type="pci" index="3" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="3"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x01" function="0x0"/>
    </controller>
    <controller type="pci" index="4" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="4"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x02" function="0x0"/>
    </controller>
    <controller type="pci" index="5" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="5"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x03" function="0x0"/>
    </controller>
    <controller type="pci" index="6" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="6"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x04" function="0x0"/>
    </controller>
    <controller type="pci" index="7" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="7"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x05" function="0x0"/>
    </controller>
    <controller type="pci" index="8" model="pci-bridge">
      <model name="pci-bridge"/>
      <target chassisNr="8"/>
      <address type="pci" domain="0x0000" bus="0x02" slot="0x06" function="0x0"/>
    </controller>
    <controller type="pci" index="9" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="9" port="0x11"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x1"/>
    </controller>
    <controller type="pci" index="10" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="10" port="0x12"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x2"/>
    </controller>
    <controller type="usb" index="0" model="qemu-xhci" ports="15">
      <address type="pci" domain="0x0000" bus="0x09" slot="0x00" function="0x0"/>
    </controller>
    <controller type="sata" index="0">
      <address type="pci" domain="0x0000" bus="0x00" slot="0x1f" function="0x2"/>
    </controller>
    <interface type="network">
      <mac address="52:54:00:73:1c:${2}"/>
      <source network="default"/>
      <model type="virtio"/>
      <driver iommu="off"/>
      <link state="up"/>
      <alias name="ua-net-0"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x04" function="0x0"/>
    </interface>
    <serial type="pty">
      <target type="isa-serial" port="0">
        <model name="isa-serial"/>
      </target>
    </serial>
    <console type="pty">
      <target type="serial" port="0"/>
    </console>
    <input type="mouse" bus="ps2"/>
    <input type="keyboard" bus="ps2"/>
    <graphics type="vnc" port="${6}" autoport="no" listen="0.0.0.0" passwd="${7}">
      <listen type="address" address="0.0.0.0"/>
    </graphics>
    <video>
      <model type="cirrus" vram="16384" heads="1" primary="yes"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x01" function="0x0"/>
    </video>
    <memballoon model="virtio">
      <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x0"/>
    </memballoon>
  </devices>
</domain>
EOF

# Create Kali machine
cat > $KALI_DIR/vm.xml << EOF
<domain type="kvm">
  <name>kali${2}</name>
  <uuid>54f8f013-67ea-4ebe-92bc-764e79428d${2}</uuid>
  <metadata>
    <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
      <libosinfo:os id="http://libosinfo.org/linux/2020"/>
    </libosinfo:libosinfo>
  </metadata>
  <memory unit="KiB">8388608</memory>
  <currentMemory unit="KiB">8388608</currentMemory>
  <vcpu placement="static">2</vcpu>
  <os>
    <type arch="x86_64" machine="pc-q35-9.1">hvm</type>
    <boot dev="hd"/>
  </os>
  <features>
    <acpi/>
    <apic/>
  </features>
  <cpu mode="host-passthrough" check="none" migratable="on"/>
  <clock offset="utc">
    <timer name="rtc" tickpolicy="catchup"/>
    <timer name="pit" tickpolicy="delay"/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <pm>
    <suspend-to-mem enabled="no"/>
    <suspend-to-disk enabled="no"/>
  </pm>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type="file" device="cdrom">
      <driver name="qemu" type="raw"/>
      <target dev="sda" bus="sata"/>
      <readonly/>
      <address type="drive" controller="0" bus="0" target="0" unit="0"/>
    </disk>
    <disk type="file" device="disk">
      <driver name="qemu" type="qcow2"/>
      <source file="$KALI_DIR/kali_base.disk.qcow2"/>
      <target dev="sdb" bus="sata"/>
      <address type="drive" controller="0" bus="0" target="0" unit="1"/>
    </disk>
    <controller type="usb" index="0" model="qemu-xhci" ports="15">
      <address type="pci" domain="0x0000" bus="0x02" slot="0x00" function="0x0"/>
    </controller>
    <controller type="pci" index="0" model="pcie-root"/>
    <controller type="pci" index="1" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="1" port="0x10"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x0" multifunction="on"/>
    </controller>
    <controller type="pci" index="2" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="2" port="0x11"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x1"/>
    </controller>
    <controller type="pci" index="3" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="3" port="0x12"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x2"/>
    </controller>
    <controller type="pci" index="4" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="4" port="0x13"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x3"/>
    </controller>
    <controller type="pci" index="5" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="5" port="0x14"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x4"/>
    </controller>
    <controller type="pci" index="6" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="6" port="0x15"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x5"/>
    </controller>
    <controller type="pci" index="7" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="7" port="0x16"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x6"/>
    </controller>
    <controller type="pci" index="8" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="8" port="0x17"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x7"/>
    </controller>
    <controller type="pci" index="9" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="9" port="0x18"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x0" multifunction="on"/>
    </controller>
    <controller type="pci" index="10" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="10" port="0x19"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x1"/>
    </controller>
    <controller type="pci" index="11" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="11" port="0x1a"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x2"/>
    </controller>
    <controller type="pci" index="12" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="12" port="0x1b"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x3"/>
    </controller>
    <controller type="pci" index="13" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="13" port="0x1c"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x4"/>
    </controller>
    <controller type="pci" index="14" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="14" port="0x1d"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x5"/>
    </controller>
    <controller type="scsi" index="0" model="virtio-scsi">
      <address type="pci" domain="0x0000" bus="0x03" slot="0x00" function="0x0"/>
    </controller>
    <controller type="sata" index="0">
      <address type="pci" domain="0x0000" bus="0x00" slot="0x1f" function="0x2"/>
    </controller>
    <controller type="virtio-serial" index="0">
      <address type="pci" domain="0x0000" bus="0x04" slot="0x00" function="0x0"/>
    </controller>
    <filesystem type="mount" accessmode="passthrough">
      <source dir="${8}"/>
      <target dir="share"/>
      <readonly/>
      <address type="pci" domain="0x0000" bus="0x07" slot="0x00" function="0x0"/>
    </filesystem>
    <interface type="network">
      <mac address="52:54:00:f8:1d:${2}"/>
      <source network="hacking${2}"/>
      <model type="virtio"/>
      <address type="pci" domain="0x0000" bus="0x01" slot="0x00" function="0x0"/>
    </interface>
    <serial type="pty">
      <target type="isa-serial" port="0">
        <model name="isa-serial"/>
      </target>
    </serial>
    <console type="pty">
      <target type="serial" port="0"/>
    </console>
    <channel type="unix">
      <target type="virtio" name="org.qemu.guest_agent.0"/>
      <address type="virtio-serial" controller="0" bus="0" port="1"/>
    </channel>
    <input type="tablet" bus="usb">
      <address type="usb" bus="0" port="1"/>
    </input>
    <input type="mouse" bus="ps2"/>
    <input type="keyboard" bus="ps2"/>
    <graphics type="vnc" port="${3}" autoport="no" listen="0.0.0.0" passwd="${7}">
      <listen type="address" address="0.0.0.0"/>
    </graphics>
    <video>
      <model type="virtio" heads="1" primary="yes"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x01" function="0x0"/>
    </video>
    <memballoon model="virtio">
      <address type="pci" domain="0x0000" bus="0x05" slot="0x00" function="0x0"/>
    </memballoon>
    <rng model="virtio">
      <backend model="random">/dev/urandom</backend>
      <address type="pci" domain="0x0000" bus="0x06" slot="0x00" function="0x0"/>
    </rng>
  </devices>
</domain>
EOF

# Start vms
cd $BASIC_DIR
sudo virsh define vm.xml
sudo virsh start suasploitable${2}-basic
cd $BASIC_DIR

cd $CLOUD_DIR
sudo virsh define vm.xml
sudo virsh start suasploitable${2}-cloud
cd $CUR_DIR

cd $CMS_DIR
sudo virsh define vm.xml
sudo virsh start suasploitable${2}-cms
cd $CUR_DIR

cd $DEVBOX_DIR
sudo virsh define vm.xml
sudo virsh start suasploitable${2}-devbox
cd $CUR_DIR

cd $KALI_DIR
sudo virsh define vm.xml
sudo virsh start kali${2}
cd $KALI_DIR

echo "Started VMs"
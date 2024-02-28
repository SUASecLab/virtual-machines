#!/bin/bash

# Note: this script requires the installation of Java 17 and ant.
# You can find their installation scripts in the 'programs' directory.
cd /home/laboratory

# Install Contiki dependencies
# See https://docs.contiki-ng.org/en/develop/doc/getting-started/Toolchain-installation-on-Linux.html

# Install dependencies for simulator and Z1
apt-get install -y build-essential doxygen \
	curl python3-serial srecord rlwrap net-tools \
	wget msp430mcu mspdebug gdb

# Install and configure wireshark
# Access rights are changed by adding /etc/sudoers.d/contiki with files provisioner
# See https://unix.stackexchange.com/questions/367866/how-to-choose-a-response-for-interactive-prompt-during-installation-from-a-shell/413011#413011
echo "wireshark-common wireshark-common/install-setuid boolean true" | sudo debconf-set-selections
apt-get install wireshark -y
usermod -a -G wireshark laboratory

# Install ARM compiler
tar -xjf /tmp/gcc-arm-none-eabi-9-2020-q2-update-x86_64-linux.tar.bz2
chown laboratory:laboratory gcc-arm-none-eabi-9-2020-q2-update -R

# Add to path
cat >>/home/laboratory/.bashrc <<EOF
export PATH="\$PATH:/home/laboratory/gcc-arm-none-eabi-9-2020-q2-update/bin"
EOF

# Install MSP430 dependencies
dpkg --add-architecture i386
apt-get update
apt-get install libc6:i386 zlib1g:i386 -y

# Install MSP430 compiler
tar -xjf /tmp/mspgcc-4.7.2-compiled.tar.bz2 -C /tmp/
cp -f -r /tmp/msp430/* /usr/local/

# CoAP client
#apt-get install npm -y
#npm install coap-cli -g

# Mosquitto MQTT broker
#apt-get install -y mosquitto mosquitto-clients

# USB access
usermod -a -G plugdev laboratory
usermod -a -G dialout laboratory

# USB stability
echo 'ATTRS{idVendor}=="0451", ATTRS{idProduct}=="16c8", ENV{ID_MM_DEVICE_IGNORE}="1"' >> /lib/udev/rules.d/77-mm-usb-device-blacklist.rules

# Clone Contiki source
cd /home/laboratory
git clone --recursive https://github.com/SUASec/contiki-ng.git
cd contiki-ng
git submodule update

# Run cooja simulator script
cat >>/home/laboratory/run_cooja.sh <<EOF
#!/bin/bash
cd /home/laboratory/contiki-ng/tools/cooja
ant run
read a
EOF

chmod a+x /home/laboratory/run_cooja.sh

# Set up video stream
apt-get install ffmpeg -y

# Show remote script
cat >>/home/laboratory/show_remote.sh <<EOF
#!/bin/bash
timeout 120 ffplay -f video4linux2 -framerate 20 -video_size 858x480 /dev/video0
read a
EOF

chmod a+x /home/laboratory/show_remote.sh

# Allow laboratory user to run Contiki development and debugging tools
cat >>/etc/sudoers.d/contiki <<EOF
laboratory $HOSTNAME = (root) NOPASSWD: /usr/bin/wireshark
laboratory $HOSTNAME = (root) NOPASSWD: /home/laboratory/contiki-ng/tools/serial-io/serialdump
laboratory $HOSTNAME = (root) NOPASSWD: /home/laboratory/contiki-ng/tools/serial-io/tunslip6
EOF

chmod 0440 /etc/sudoers.d/contiki
chown root:root /etc/sudoers.d/contiki
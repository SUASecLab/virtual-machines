#!/bin/env/python3

from configuration import Configuration
import os
import password
from random import randint

def unattended(conf: Configuration) -> Configuration:
    if conf.gacha.pull(60):
        conf.install_script += """
apt-get install -y unattended-upgrades

cat >>/etc/apt/apt.conf.d/10periodic <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
    """

        conf.conf_dict["unattended-upgrades"]["installed"] = True
    else:
        conf.conf_dict["unattended-upgrades"]["installed"] = False
    return conf


def ssh(conf: Configuration) -> Configuration:
    # 0. Change default port with probability of 30%
    if conf.gacha.pull(30):
        new_port = randint(2000, 60000)
        conf.install_script += f"""
sed -i "s|#Port 22|Port {new_port}|g" /etc/ssh/sshd_config
        """
        conf.conf_dict["ssh"]["port"] = str(new_port)
        conf.flags.append(str(new_port))
    else:
        conf.conf_dict["ssh"]["port"] = str(22)

    # 1 Permit root login: 20% yes, 10% prohibit-password, 70% no
    if conf.gacha.pull(20):
        # Permit root login
        conf.install_script += """
sed -i "s|#PermitRootLogin prohibit-password|PermitRootLogin yes #flag|g" /etc/ssh/sshd_config
        """

        conf.conf_dict["ssh"]["permit_root_login"] = "yes"
        conf.flags.append("PermitRootLogin")
    elif conf.gacha.pull(10):
        # Prohibit-password
        conf.install_script += """
sed -i "s|#PermitRootLogin prohibit-password|PermitRootLogin prohibit-password #flag|g" /etc/ssh/sshd_config
        """

        conf.conf_dict["ssh"]["permit_root_login"] = "prohibit-password"
        conf.flags.append("prohibit-password")
    else:
        # No
        conf.conf_dict["ssh"]["permit_root_login"] = "no"

    # 2 Enable password auth (30%) or pubkey auth (70%)
    if conf.gacha.pull(30, True):
        # Password auth
        conf.install_script += """
sed -i "s|#PubkeyAuthentication yes|PubkeyAuthentication no|g" /etc/ssh/sshd_config
sed -i "s|#PasswordAuthentication yes|PasswordAuthentication yes #flag|g" /etc/ssh/sshd_config
        """
        conf.conf_dict["ssh"]["pubkey_auth"] = False
        conf.conf_dict["ssh"]["password_auth"] = True
        conf.flags.append("PasswordAuthentication")
    else:
        # Pubkey auth
        conf.install_script += """
sed -i "s|#PubkeyAuthentication yes|PubkeyAuthentication yes #flag|g" /etc/ssh/sshd_config
sed -i "s|#PasswordAuthentication yes|PasswordAuthentication no|g" /etc/ssh/sshd_config
        """

        conf.conf_dict["ssh"]["pubkey_auth"] = True
        conf.conf_dict["ssh"]["password_auth"] = False

    # 3 Install fail2ban (30%)
    if conf.gacha.pull(30):
        conf.install_script += """
apt-get install -y fail2ban
        """

        conf.conf_dict["ssh"]["fail2ban"] = True
    else:
        conf.conf_dict["ssh"]["fail2ban"] = False

    return conf

def docker(conf: Configuration) -> Configuration:
    conf.conf_dict["docker"]["available"] = True

    conf.install_script += """
apt-get update
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update

apt-get install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

systemctl enable docker.service
systemctl enable containerd.service
    """

    if conf.gacha.pull(30, True):
        # Expose Docker TCP socket
        conf.install_script += """
cat >> /etc/docker/daemon.json <<EOF
{"hosts": ["tcp://0.0.0.0:2375", "unix:///var/run/docker.sock"]}
EOF

mkdir -p /etc/systemd/system/docker.service.d/

cat >> /etc/systemd/system/docker.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --config-file /etc/docker/daemon.json
EOF
        """
        conf.conf_dict["docker"]["tcp_exposed"] = True
    else:
        conf.conf_dict["docker"]["tcp_exposed"] = False

    return conf


def portainer(conf: Configuration) -> Configuration:
    # Generate secure password: 70%
    if conf.gacha.pull(30, True):
        # Insecure password 
        conf.conf_dict["portainer"]["password_type"] = "insecure"
        conf.conf_dict["portainer"]["password"] = password.insecure_password()
        conf.flags.append(conf.conf_dict["portainer"]["password"])
    else:
        # Secure password 
        conf.conf_dict["portainer"]["password_type"] = "secure"
        conf.conf_dict["portainer"]["password"] = password.secure_password()

    conf.install_script += f"""
cd /opt
mv /tmp/portainer.yml .
echo -n {conf.conf_dict["portainer"]["password"]} > /opt/portainer_password
docker compose -f portainer.yml up -d
    """

    # Append container name to flags
    conf.flags.append("portainer")
    return conf

def change_vagrant_password(conf: Configuration) -> Configuration:
    conf.conf_dict["vagrant_password"] = os.environ["SSH_PASSWORD"]
    return conf
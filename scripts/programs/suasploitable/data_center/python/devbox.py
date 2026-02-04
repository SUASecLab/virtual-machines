#!/bin/env python3

from configuration import *
import environment
import identities
import password

import gitea_setup
import jenkins_setup
import rocket_chat_setup

import subprocess

config = Configuration()

# Unattended upgrades
config = environment.unattended(config)

# SSH
config = environment.ssh(config)

# Generate identities
config = identities.generate_identities(config, True)

# Docker
config = environment.docker(config)

# Setup DevBox
# Copy all required files
config.install_script += """
# Create directories
DEVBOX_DIR=/srv/devbox/
mkdir -p $DEVBOX_DIR/gitea
mkdir -p $DEVBOX_DIR/jenkins/init_scripts
mkdir -p $DEVBOX_DIR/jenkins/plugins
mkdir -p $DEVBOX_DIR/rocket_chat

# Copy compose and setup scripts
mv /tmp/docker-compose.yml $DEVBOX_DIR
mv /tmp/environment $DEVBOX_DIR/.env

# Copy gitea configuration files
mv /tmp/app.ini $DEVBOX_DIR/gitea/
mv /tmp/Dockerfile.gitea $DEVBOX_DIR/gitea/Dockerfile

# Copy Jenkins configuration files
mv /tmp/00-users.groovy $DEVBOX_DIR/jenkins/init_scripts/
mv /tmp/01-ctf.groovy $DEVBOX_DIR/jenkins/init_scripts/
mv /tmp/ionicons-api.hpi $DEVBOX_DIR/jenkins/plugins/
mv /tmp/matrix-auth.hpi $DEVBOX_DIR/jenkins/plugins/
mv /tmp/Dockerfile.jenkins $DEVBOX_DIR/jenkins/Dockerfile

# Scripts that are reused
cp /tmp/gitea_setup.py /srv/
cp /tmp/jenkins_setup.py /srv/
cp /tmp/rocket_chat_setup.py /srv/
cp /tmp/configuration.py /srv/
cp /tmp/password.py /srv/
cp /tmp/gacha.py /srv/

# Access rights
chown vagrant:vagrant $DEVBOX_DIR -R
"""

# Set service properties
# Portainer version (latest: 60%)
if config.gacha.pull(40, True):
    config.conf_dict["portainer"]["version"] = "2.19.4"
    config.flags.append("CVE-2024-29296")
else:
    config.conf_dict["portainer"]["version"] = "2.31.3"
    config.install_script += """
sed -i 's|PORTAINER_VERSION=2.19.4|PORTAINER_VERSION=2.31.3|g' $DEVBOX_DIR/.env
    """

# RocketChat version (latest: 40%)
if config.gacha.pull(40, True):
    config.conf_dict["rocket_chat"]["version"] = "7.7"
    config.install_script += """
sed -i 's|ROCKET_CHAT_VERSION=4.8.1|ROCKET_CHAT_VERSION=7.7|g' $DEVBOX_DIR/.env
    """
else:
    config.conf_dict["rocket_chat"]["version"] = "4.8.1"
    config.flags.append("CVE-2022-35246")

# Change Rocket Chat admin password (40%)
if config.gacha.pull(40, True):
    # Secure: 70%
    if config.gacha.pull(70):
        config.conf_dict["rocket_chat"]["admin_password"] = password.secure_password()
    else:
        config.conf_dict["rocket_chat"]["admin_password"] = password.insecure_password()
    config.install_script += f"""
sed -i 's|ROCKET_CHAT_ADMIN_PASSSWORD=winner|ROCKET_CHAT_ADMIN_PASSSWORD={config.conf_dict["rocket_chat"]["admin_password"]}|g' $DEVBOX_DIR/.env
sed -i 's|ADMIN_PASSWORD = "winner"|ADMIN_PASSWORD = "{config.conf_dict["rocket_chat"]["admin_password"]}"|g' /srv/rocket_chat_setup.py
    """
else:
    config.conf_dict["rocket_chat"]["admin_password"] = "winner"
    config.flags.append("winner")

# Gitea version (latest: 40%)
if config.gacha.pull(40, True):
    config.conf_dict["gitea"]["version"] = "1.24"
    config.install_script += """
sed -i 's|1.22.0|1.24|g' $DEVBOX_DIR/gitea/Dockerfile
    """
else:
    config.conf_dict["gitea"]["version"] = "1.22.0"
    config.flags.append("CVE-2024-6886")

# Change gitea admin password (40%)
if config.gacha.pull(40, True):
    # Secure: 70%
    if config.gacha.pull(70):
        config.conf_dict["gitea"]["admin_password"] = password.secure_password()
    else:
        config.conf_dict["gitea"]["admin_password"] = password.insecure_password()
    config.install_script += f"""
sed -i 's|ADMIN_PASSWORD = "midnight"|ADMIN_PASSWORD = "{config.conf_dict["gitea"]["admin_password"]}"|g' /srv/gitea_setup.py
    """
    # Password is also adjusted below in the docker command creating the user
else:
    config.conf_dict["gitea"]["admin_password"] = "midnight"
    config.flags.append("midnight")

# Jenkins version (latest: 40%)
if config.gacha.pull(40, True):
    config.conf_dict["jenkins"]["version"] = "2.504.3-lts"
    config.install_script += """
sed -i 's|2.426.2-lts|2.504.3-lts|g' $DEVBOX_DIR/jenkins/Dockerfile
    """
else:
    config.conf_dict["jenkins"]["version"] = "2.426.2-lts"
    config.flags.append("CVE-2024-23897")

# Change Jenkins admin password (40%)
if config.gacha.pull(40, True):
    # Secure: 70%
    if config.gacha.pull(70):
        config.conf_dict["jenkins"]["admin_password"] = password.secure_password()
    else:
        config.conf_dict["jenkins"]["admin_password"] = password.insecure_password()
    config.install_script += f"""
sed -i 's|power|{config.conf_dict["jenkins"]["admin_password"]}|g' $DEVBOX_DIR/jenkins/init_scripts/00-users.groovy
sed -i 's|ADMIN_PASSWORD = "power"|ADMIN_PASSWORD = "{config.conf_dict["jenkins"]["admin_password"]}"|g' /srv/jenkins_setup.py
    """
else:
    config.conf_dict["jenkins"]["admin_password"] = "power"
    config.flags.append("power")

# Change jenkins flag
config.conf_dict["jenkins"]["build_flag"] = password.secure_password()
config.install_script += f"""
sed -i 's|FLAG|flag:{config.conf_dict["jenkins"]["build_flag"]}|g' $DEVBOX_DIR/jenkins/init_scripts/01-ctf.groovy
"""

# Start compose script
config.install_script += """
cd $DEVBOX_DIR
docker compose -f docker-compose.yml up -d
"""

# Add patched services
config.install_script += """
cd /srv
# Fixed services
wget https://ftp.drupal.org/files/projects/drupal-10.6.2.tar.gz
wget https://wordpress.org/latest.zip -O wordpress-latest.zip
wget https://download.nextcloud.com/server/releases/latest.zip -O nextcloud-latest.zip
wget https://download.pureftpd.org/pub/pure-ftpd/releases/pure-ftpd-1.0.53.tar.gz

# Populate local registry
docker pull seafileltd/seafile-mc:13.0-latest
docker tag seafileltd/seafile-mc:13.0-latest localhost:5000/seafileltd/seafile-mc:13.0-latest
docker push localhost:5000/seafileltd/seafile-mc:13.0-latest

docker pull portainer/portainer-ce:alpine-sts
docker tag portainer/portainer-ce:alpine-sts localhost:5000/portainer/portainer-ce:alpine-sts
docker push localhost:5000/portainer/portainer-ce:alpine-sts

docker pull portainer/agent:alpine-sts
docker tag portainer/agent:alpine-sts localhost:5000/portainer/agent:alpine-sts
docker push localhost:5000/portainer/agent:alpine-sts

docker pull rocket.chat:latest
docker tag rocket.chat:latest localhost:5000/rocket.chat:latest
docker push localhost:5000/rocket.chat:latest

docker pull jenkins/jenkins:latest
docker tag jenkins/jenkins:latest localhost:5000/jenkins/jenkins:latest
docker push localhost:5000/jenkins/jenkins:latest

docker pull gitea/gitea:latest
docker tag gitea/gitea:latest localhost:5000/gitea/gitea:latest
docker push localhost:5000/gitea/gitea:latest
"""
# Configure services

# Add postinstall script
config.install_script += f"""
cat > /etc/systemd/system/postinstall.service <<EOF
[Unit]
Description=Postinstall script
[Service]
Type=simple
ExecStart=/srv/postinstall.sh
[Install]
WantedBy=multi-user.target
EOF

cat > /srv/postinstall.sh <<EOF
#!/bin/bash

sleep 60
docker exec gitea /app/gitea/gitea admin user create --username root --password {config.conf_dict["gitea"]["admin_password"]} --email admin@suaseclab.de --admin --config /etc/gitea/app.ini /bin/bash
sleep 5

source /opt/venv/bin/activate
cd /srv
python /srv/gitea_setup.py
python /srv/jenkins_setup.py
python /srv/rocket_chat_setup.py

deactivate
systemctl disable postinstall.service

rm -rf /opt/venv
rm /srv/*.py
rm /srv/*.json
rm -rf /srv/__pycache__
rm /srv/postinstall.sh

wait 5
reboot now
EOF

chmod +x /srv/postinstall.sh
systemctl enable postinstall.service
"""

# Configure GiTea
config = gitea_setup.configure(config)

# Configure Jenkins
config = jenkins_setup.configure(config)

# Configure Rocket Chat
config = rocket_chat_setup.configure(config)

# Disable registration in Gitea (60%)

if not config.gacha.pull(40, True):
    config.conf_dict["gitea"]["registration_enabled"] = True
else:
    config.install_script += """
echo "docker exec gitea /bin/sed -i 's|DISABLE_REGISTRATION = false|DISABLE_REGISTRATION = true|g' /etc/gitea/app.ini" >> /srv/postinstall.sh
echo "docker restart gitea" >> /srv/postinstall.sh
"""
    config.conf_dict["gitea"]["registration_enabled"] = False

# Joker
config = password.joker(config)

# Get vagrant password
config = environment.change_vagrant_password(config)

# Write configuration
config.write_configuration()
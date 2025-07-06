#!/bin/env python3
from configuration import Configuration
import random
import string

def insecure_password(password_list="/tmp/500-worst-passwords.txt"):
    with open(password_list) as passwords:
        # Get number of lines
        nr = 0
        for line in passwords:
            nr += 1

        # Correct off-by-one
        nr -= 1
        
        # Move cursor to beginning
        passwords.seek(0)
        
        # Get random line
        nr = random.randint(0, nr)
        
        # Get password for that line
        for selection, line in enumerate(passwords):
            if selection == nr:
                return line.strip()

def secure_password():
    return "".join(random.choice(string.ascii_letters) for i in range(20))

def joker(conf) -> Configuration:
    # Set username and password
    credentials = insecure_password(password_list="/tmp/ssh-betterdefaultpasslist.txt")

    # Username should not be {root, vagrant}
    while credentials.startswith("root") or credentials.startswith("vagrant"):
        credentials = insecure_password(password_list="/tmp/ssh-betterdefaultpasslist.txt")

    credentials = credentials.split(":")
    username = credentials[0]
    password = credentials[1]

    conf.conf_dict["joker"]["username"] = username
    conf.conf_dict["joker"]["password"] = password

    # Set flag
    flag = secure_password()
    conf.flags.append(flag)
    conf.flags.append(password)

    # Write changes
    conf.install_script += f"""
sed -i "s|USERNAME|{username}|g" /opt/joker.sh
sed -i "s|PASSWORD|{password}|g" /opt/joker.sh
sed -i "s|FLAG|{flag}|g" /opt/joker.sh
    """

    return conf
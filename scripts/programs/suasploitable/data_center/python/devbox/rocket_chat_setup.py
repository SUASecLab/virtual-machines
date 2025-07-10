from configuration import Configuration
import password 

import json
import requests
import time

ROCKET_CHAT_URL = "http://localhost:3000"
ADMIN_USERNAME = "admin"
ADMIN_PASSWORD = "winner"

def configure(conf) -> Configuration:
    # Create configuration
    configuration = dict()
    configuration["users"] = conf.conf_dict["identities"]

    flag = password.secure_password()
    conf.flags.append(flag)
    conf.conf_dict["rocket_chat"]["welcome_flag"] = flag
    configuration["messages"] = ["🚩 Welcome to the CTF!", f"flag:{flag}", "Happy hacking!"]

    disable_registration = not conf.gacha.pull(40, True)
    conf.conf_dict["rocket_chat"]["registration_enabled"] = not disable_registration
    configuration["disable_registration"] = disable_registration

    # Write file
    with open("/srv/rocket_chat.json", "w") as conf_file:
        json.dump(configuration, conf_file)

    return conf

def send_message(token, user_id, text, session):
    session.post(
        url=f"{ROCKET_CHAT_URL}/api/v1/chat.postMessage",
        headers={
            "X-Auth-Token": token,
            "X-User-Id": user_id
        },
        json={
            "channel": f"#ctf",
            "text": text
        }
    )

def create_account(token, admin_id, user, channel_id, session):
    user_data = {
        "name": f"{user['firstName'], user['lastName']}",
        "email": f"{user['userName']}@suaseclab.de",
        "username": user["userName"],
        "password": user["password"],
        "verified": True,
        "joinDefaultChannels": False,
        "roles": ["user"]
    }

    headers={
        "X-Auth-Token": token,
        "X-User-Id": admin_id
    }

    # Create account
    user_request = session.post(
        url=f"{ROCKET_CHAT_URL}/api/v1/users.create",
        headers=headers,
        json=user_data
    )

    if user_request.status_code != 200:
        print("Could not create user")
        return

    user_response = user_request.json()
    user_id = user_response["user"]["_id"]

    # Add to channel
    session.post(
        url=f"{ROCKET_CHAT_URL}/api/v1/channels.invite",
        headers=headers,
        json={
            "roomId": channel_id,
            "userId": user_id
        }
    )

if __name__ == "__main__":
    # Open configuration file
    with open("/srv/rocket_chat.json", "r") as conf_file:
        configuration = json.load(conf_file)

        # Create session
        session = requests.Session()

        # 1. Wait until rocket chat is ready
        while True:
            try:
                if session.get(f"{ROCKET_CHAT_URL}/api/info").status_code == 200:
                    break
            except:
                print("Wainting a little bit longer for RocketChat")
            time.sleep(5)

        # 2. Login
        admin_request = session.post(
            url=f"{ROCKET_CHAT_URL}/api/v1/login",
            json={
                "user": ADMIN_USERNAME,
                "password": ADMIN_PASSWORD
            })
        admin_request.raise_for_status()
        admin_data = admin_request.json()["data"]
        admin_token = admin_data["authToken"]
        admin_id = admin_data["userId"]

        # 3. Create CTF channel
        headers={
            "X-Auth-Token": admin_token,
            "X-User-Id": admin_id
        }

        session.post(
            url=f"{ROCKET_CHAT_URL}/api/v1/channels.create",
            headers=headers,
            json = {
                "name": "ctf"
            })

        # 4. Get channel ID
        channel_request = session.get(
            url=f"{ROCKET_CHAT_URL}/api/v1/channels.info?roomName=ctf",
            headers=headers
        )
        
        channel_response = channel_request.json()
        channel_id = channel_response["channel"]["_id"]

        # 5. Send messages
        for message in configuration["messages"]:
            send_message(admin_token, admin_id, message, session)

        # 6. Create accounts
        for user in configuration["users"]:
            create_account(admin_token, admin_id, user, channel_id, session)
        
        # 7. Disable registration if requested
        if configuration["disable_registration"] == True:
            session.post(
                url=f"{ROCKET_CHAT_URL}/api/v1/settings/Accounts_RegistrationForm",
                headers=headers,
                json={
                    "value": "Disabled"
                }
            )

    session.close()
    print("Done setting up Rocket Chat")
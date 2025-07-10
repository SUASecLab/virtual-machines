from configuration import Configuration
import password

import os
import json
import random
import requests
from requests.auth import HTTPBasicAuth
import subprocess
import time

# Constants
GITEA_URL = "http://localhost:80"
ADMIN_USERNAME = "root"
ADMIN_PASSWORD = "midnight"

def create_repo(repo_name, flag, user, password, private, session):
    # 1. Create repository locally and add the flag
    path = f"/tmp/ctf/{repo_name}"
    os.makedirs(path)
    with open(f"/tmp/ctf/{repo_name}/flag.txt", "w") as flag_file:
        flag_file.write(f"flag:{flag}")

    # 2. Create the repository in GiTea
    repo_properties = {
        "auto_init": False,
        "description": "CtF repository",
        "name": repo_name,
        "private": private
    }

    request = session.post(
        url=f"{GITEA_URL}/api/v1/user/repos",
        json=repo_properties,
        auth=HTTPBasicAuth(user, password)
    )

    if request.status_code != 201:
        print(f"Could not create repo {repo_name}, {request.text}")
        return

    repo_url = request.json()["clone_url"]
    repo_url_auth = repo_url.replace("http://", f"http://{user}:{password}@")
    
    # 3. Push repo
    os.chdir(path)

    subprocess.run(["git", "init", "-b", "main"])
    subprocess.run(["git", "config", "user.name", user])
    subprocess.run(["git", "config", "user.email", f"{user}@suaseclab.de"])
    subprocess.run(["git", "add", "."])
    subprocess.run(["git", "commit", "-m", "Initial commit"])
    subprocess.run(["git", "remote", "add", "origin", repo_url_auth])
    subprocess.run(["git", "push", "-u", "origin", "main"])

def create_user(identity, session):
    # Set up user structure
    user = {
        "email": f"{identity['userName']}@suaseclab.de",
        "full_name": f"{identity['firstName']} {identity['lastName']}",
        "login_name": identity["userName"],
        "must_change_password": False,
        "password": identity["password"],
        "restricted": False,
        "send_notify": False,
        "username": identity["userName"],
    }


    # Send API request to add user
    request = session.post(
        url=f"{GITEA_URL}/api/v1/admin/users",
        json=user,
        auth=HTTPBasicAuth(ADMIN_USERNAME, ADMIN_PASSWORD)
    )

    if request.status_code != 201:
        print(f"Could not create user: {request.status_code}: {request.text}")

def configure(conf) -> Configuration:
    # Iterate over all identities
    users = []
    for identity in conf.conf_dict["identities"]:
        # Add user
        user = identity

        # Add repo(s) (70%)
        repos = []
        if conf.gacha.pull(70):
            for i in range(random.randint(1, 4)):
                repo_name = f"{identity['userName']}-{str(i)}"
                flag = password.secure_password()
                conf.flags.append(flag)
                private = conf.gacha.pull(80) # Repo is private with prob of 80%

                # For gitea configuration data structure
                repo = dict()
                repo["name"] = repo_name
                repo["flag"] = flag
                repo["private"] = private
                repos.append(repo)

        identity["repos"] = repos
        user["repos"] = repos
        users.append(user)

    # Write user data structure
    with open("/srv/gitea.json", "w") as conf_file:
        users_dict = dict()
        users_dict["users"] = users
        json.dump(users_dict, conf_file)
    
    return conf

if __name__ == "__main__":
    # Create session
    session = requests.Session()

    # Open configuration file
    with open("/srv/gitea.json", "r") as conf_file:
        configuration = json.load(conf_file)
        users = configuration["users"]

        for user in users:
            create_user(user, session)
            for repo in user["repos"]:
                time.sleep(2)
                create_repo(repo["name"], repo["flag"], user["userName"],
                    user["password"], repo["private"], session)

    session.close()
    print("Done setting up GiTea")
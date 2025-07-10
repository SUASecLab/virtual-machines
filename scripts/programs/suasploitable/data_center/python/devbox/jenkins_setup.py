from configuration import Configuration

import json
import requests
from requests.auth import HTTPBasicAuth

# Variables
JENKINS_URL = "http://localhost:8080"
ADMIN_USERNAME = "admin"
ADMIN_PASSWORD = "power"

def configure(conf) -> Configuration:
    # Create configuration file
    conf_dict = dict()
    conf_dict["users"] = conf.conf_dict["identities"]

    # Registration enabled (40%)
    isRegistrationEnabled = conf.gacha.pull(60, True)
    conf_dict["registrationEnabled"] = isRegistrationEnabled
    conf.conf_dict["jenkins"]["registration_enabled"] = isRegistrationEnabled

    # Write configuration file
    with open("/srv/jenkins.json", "w") as conf_file:
        json.dump(conf_dict, conf_file)

    return conf

if __name__ == "__main__":
    # Open configuration file
    with open("/srv/jenkins.json", "r") as conf_file:
        configuration = json.load(conf_file)

        # 1. Create session
        session = requests.Session()

        # 2. Get CSRF token
        csrf_request = session.get(
            url=f"{JENKINS_URL}/crumbIssuer/api/json",
            auth=HTTPBasicAuth(ADMIN_USERNAME, ADMIN_PASSWORD)
        )

        csrf_response = csrf_request.json()
        csrf_field = csrf_response["crumbRequestField"]
        csrf_token = csrf_response["crumb"]
        csrf_data = {
            csrf_field: csrf_token
        }

        # 3. Get API token
        api_token_request = session.post(
            url=f"{JENKINS_URL}/user/{ADMIN_USERNAME}/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken",
            data=csrf_data,
            auth=HTTPBasicAuth(ADMIN_USERNAME, ADMIN_PASSWORD)
        )

        api_token_response = api_token_request.json()
        api_token = api_token_response["data"]["tokenValue"]

        # 4. Create users
        for identity in configuration["users"]:
            user_data = {
                "username": identity["userName"],
                "password1": identity["password"],
                "password2": identity["password"],
                "fullname": f"{identity['firstName']} {identity['lastName']}",
                "email": f"{identity['userName']}@suaseclab.de",
                "Submit": "Create User"
            }

            identity_request = session.post(
                url=f"{JENKINS_URL}/securityRealm/createAccount",
                headers=csrf_data,
                data=user_data,
                auth=HTTPBasicAuth(ADMIN_USERNAME, api_token)
            )

            if identity_request.status_code != 200:
                print(f"Could not create user {identity['userName']}: {identity_request.text}")

        # 5. Disable signup
        if configuration["registrationEnabled"] == False:
            signup_script = """
    import jenkins.model.*
    import hudson.security.*

    def instance = Jenkins.getInstance()
    def realm = new hudson.security.HudsonPrivateSecurityRealm(false)
    instance.setSecurityRealm(realm)
    instance.save()
            """

            signup_request = session.post(
                url=f"{JENKINS_URL}/scriptText",
                data={
                    "script": signup_script
                },
                auth=HTTPBasicAuth(ADMIN_USERNAME, api_token)
            )
        
    session.close()
    print("Done setting up Jenkins")
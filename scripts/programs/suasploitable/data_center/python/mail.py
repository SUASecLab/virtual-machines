import smtplib
from configuration import Configuration
import json
import password
from random import choice

def random_correspondents(identities) -> dict:
    result = dict()
    result["sender"] = choice(identities)
    result["recipient"] = result["sender"]
    while result["recipient"] == result["sender"]:
        result["recipient"] = choice(identities)

    return result

def construct_mail(text, subject, correspondents) -> dict:
    result = dict()
    result["Body"] = text
    result["Subject"] = subject
    result["From"] = correspondents["sender"]["userName"] + "@suaseclab.de"
    result["To"] = correspondents["recipient"]["userName"] + "@suaseclab.de"
    return result

def send_mail(config) -> Configuration:
    messages = []
    identities = config.conf_dict["identities"]

    # Welcome message
    correspondents = random_correspondents(identities)
    text = f"""Dear {correspondents["recipient"]["firstName"]},

Welcome to our team. To access our services, please use the following credentials:

Username: {correspondents["recipient"]["userName"]}
Password: {correspondents["recipient"]["password"]}

If you need assistance please let me know
- {correspondents["sender"]["firstName"]}
"""

    if config.gacha.pull(90):
        messages.append(construct_mail(text, "Welcome back!", correspondents))

    # Password change request
    correspondents = random_correspondents(identities)
    text = f"""Dear {correspondents["recipient"]["firstName"]},

We rest your credentials as requested. You can find your new credentials below:

User: {correspondents["recipient"]["userName"]}
Password: {correspondents["recipient"]["password"]}

Please change your password after logging in for the first time.

Best regards,

{correspondents["sender"]["firstName"]}
    """

    if config.gacha.pull(80):
        messages.append(construct_mail(text, "Your password change request", correspondents))

    # Lost laptop
    correspondents = random_correspondents(identities)
    text = f"""Dear {correspondents["recipient"]["firstName"]},

Unfortunately I lost my laptop in the train. It was not encrypted.
The following credentials were stored on it:

User: {correspondents["sender"]["userName"]}
Password: {correspondents["sender"]["password"]}

{correspondents["sender"]["firstName"]}
"""

    if config.gacha.pull(70):
        messages.append(construct_mail(text, "Lost laptop notification", correspondents))
    
    # OOO message
    correspondents = random_correspondents(identities)
    text = f"""
Hi,

I'm out-of-office until Thursday. In case of emergencies, please use the following credentials for the database:
{correspondents["sender"]["userName"]}:{correspondents["sender"]["password"]}

{correspondents["sender"]["firstName"]}
    """

    if correspondents["sender"]["dbUserExists"] and config.gacha.pull(60):
        messages.append(construct_mail(text, "OOO notification", correspondents))

    # Weird crontab
    correspondents = random_correspondents(identities)
    text = f"""Dear {correspondents["recipient"]["firstName"]},

Can you please check the elevator.sh script in /opt that runs on our servers? It's called daily by a cronjob and seems to behave weird.
{correspondents["sender"]["firstName"]}
"""

    if config.gacha.pull(80):
        messages.append(construct_mail(text, "Weird crontab behavior", correspondents))

    # Welness update
    flag = password.secure_password()
    config.flags.append(flag)
    text = f"""
For everyone who is interested: new yoga classes are available on Tuesdays.

HR reminder for the following weeks:
- Drink enough when it is warm outside
- We are unavailable next Wednessday due to a training
- flag:{flag}

- HR
    """
    for identity in identities:
        correspondents = {
            "sender": identities[0],
            "recipient": identity
        }
        messages.append(construct_mail(text, "Your wellness update", correspondents))

    # Newsletter

    text = """
Hi Team,

Here are the latest updates and reminders for the week:

---

🛠️ **Infrastructure Notes**

- Maintenance window scheduled for **Friday, 02:00–04:00 UTC**. Network disruptions may occur.

🎉 **Recognition**

- Congratulations to the interns for completing the onboarding sprint!

📅 **Upcoming**

- Wednesday: Tech Talk on CI/CD security.
- Friday: Virtual happy hour, link to follow.

---

Have a productive week!  
– SUASecLab Corp Communications    
    """

    for identity in identities:
        correspondents = {
            "sender": identities[0],
            "recipient": identity
        }
        messages.append(construct_mail(text, "Weekly newsletter", correspondents))


    with open("/tmp/outbox.json", "w") as outbox:
        messages_outbox = dict()
        messages_outbox["mails"] = messages
        json.dump(messages_outbox, outbox)

    # Send mail
    config.install_script += """
chmod a+x /tmp/sendmail.py
python /tmp/sendmail.py
    """

    config.conf_dict["mails"] = messages

    return config
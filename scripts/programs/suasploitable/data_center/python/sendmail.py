#!/bin/env python3

from email.mime.text import MIMEText
import json
import smtplib

mails = []

with open("/tmp/outbox.json", "r") as outbox:
    mails_json = json.load(outbox)
    mails_json = mails_json["mails"]

    for mail_json in mails_json:
        mail_mime = MIMEText(mail_json["Body"])
        mail_mime["Subject"] = mail_json["Subject"]
        mail_mime["From"] = mail_json["From"]
        mail_mime["To"] = mail_json["To"]
        mails.append(mail_mime)

with smtplib.SMTP("suaseclab.de", 25) as server:
    for mail in mails:
        server.send_message(mail)

    print("Sent mails")

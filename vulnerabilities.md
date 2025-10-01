List of Vulnerabilities  
=============================

General information
-----------
- Insecure passwordsd are chosen from the list of most used passwords (see `files/500-worst-passwords`) which bases on the [SecLists list](https://github.com/danielmiessler/SecLists/blob/master/Passwords/Common-Credentials/500-worst-passwords.txt)
- The randomly build VMs feature a pity mechanism that ensures that there are sufficient vulnerabilities in each generated VM. This pity mechanism works as follows: if a predefined number of vulnerabilities was skipped, the next vulnerability is included regardless of its probablity. For mor details refer to the `scripts/programs/suasploitable/data_center/python` scripts.


Basic
--------------------

- OpenSSH misconfiguation: Password login is allowed, administrator login is possible with easy to guess password (password list). Further credentials can be figured out by evaluating `/etc/passwd` and using a password list to check these passwords.
- Jorani: this is a web application for work time management. Our setup runs version 1.0.0 which allows reading server information using an [XSS attack](https://www.exploit-db.com/exploits/51715). Furthermore, [starting a reverse shell](https://www.cve.org/CVERecord?id=CVE-2023-26469) is possible.
- SQL misconfiguration: The SQL server can be reached from the outside. Multiple username-password combinations can be guessed using according lists.
- ActiveMQ message broker: Here we use ActiveMQ version 5.18.0 which suffers a [RCE](https://www.bsi.bund.de/SharedDocs/Cybersicherheitswarnungen/DE/2023/2023-283657-1032.pdf?__blob=publicationFile&v=2). As we run this process as root, exploiting the vulnerability leads to a root shell.
- TCP server: this is a self-developed TCP server that is queried regularly by the Kali VM. In these requestes, flags are communicated that can be captured with Wireshark. Furthermore, a hidden functionality releases a flag when called.
- JuiceShop: this VM runs [JuiceShop](https://owasp.org/www-project-juice-shop/) in a Docker container. It can be used to learn about web application security


General vulnerabilities in all randomly build VMs
-----------

|Service|Security issue|Probability|
|-------|--------------|-----------|
|SSH|Root login allowed|20%|
|SSH|Password login allowed|30%|
|SSH|No intrusion prevention|70%|


CMS and mail server
------------------

|Service|Security issue|Probability|
|-------|--------------|-----------|
|DB|Insecure root password|20%|
|DB|Remote login allowed|30%|
|DB|Admin account uses insecure password|30%|
|Webserver|No TLS|30%|
|Drupal|Version 10.1.3 with vulnerability CVE-2023-5256|40%|
|Drupal|Insecure password for web administration user|30%|
|Wordpress|Insecure password for system user|30%|
|Wordpress|[Vulnerable version 6.5](https://wordpress.org/news/2024/04/wordpress-6-5-2-maintenance-and-security-release/)|33%|
|Wordpress|[Vulnerable version 6.4.2](https://wordpress.org/news/2024/01/wordpress-6-4-3-maintenance-and-security-release/)|33%|
|Wordpress|Web administration user with insecure password|20%|
|Drupal & Wordpress|DB user with insecure password|30%|
|Drupal & Wordpress|DB user has rights to access all databases|60%|
|Postfix|Everyone can read system files containing the mails|30%|
|Postfix|No usage of TLS|20%|
|Postfix|TLS is not enforced even tough certificates are present|20%|

Cloud and file server
----------------

|Service|Security issue|Probability|
|-------|--------------|-----------|
|DB|Insecure root password|20%|
|DB|Remote login allowed|30%|
|DB|Admin account uses insecure password|30%|
|Webserver|No TLS|30%|
|SeaFile|[Vulnerable version 11.0.11](https://manual.seafile.com/11.0/changelog/server-changelog/#11011-2024-08-07)|30%|
|SeaFile|Usage of default credentials|20%|
|Portainer|Insecure password if portainer is available (70%)|30%|
|Nextcloud|Insecure DB user password|30%|
|Nextcloud|DB user has rights for all databases|60%|
|Nextcloud|Administrator user with insecure password|30%|
|Nextcloud|[Vulnerable version 28.0.3](https://nvd.nist.gov/vuln/detail/CVE-2024-37882)|30%|
|Samba|Public share|40%|
|FTP|Anonymous access possible|70%|
|FTP|Anonymous file upload possible|70%|
|FTP|No chroot|10%|
|PureFTPd|[Vulnerable version 1.0.51](https://nvd.nist.gov/vuln/detail/CVE-2024-48208)|70%|

Developer's Box
---------------


|Service|Security issue|Probability|
|-------|--------------|-----------|
|Docker|Public TCP port|30%|
|Portainer|[Vulnerable version 2.19.4](https://nvd.nist.gov/vuln/detail/CVE-2024-29296)|40%|
|RocketChat|[Vulnerable version 4.8.1](https://nvd.nist.gov/vuln/detail/CVE-2022-35246)|60%|
|Gitea|[Vulnerable version 1.22.0](https://nvd.nist.gov/vuln/detail/CVE-2024-6886)|60%|
|Jenkins|[Vulnerable version 2.426-2](https://nvd.nist.gov/vuln/detail/CVE-2024-23897)|60%|

The following vulnerabilities are configured for RocketChat, Gitea and Jenkins each:

|Security issue|Probability|
|-------------|-----------|
|Keep default credentials|60%|
|Use insecure password if password is changed (40%)|30%|
|Third party signup allowed|40%|

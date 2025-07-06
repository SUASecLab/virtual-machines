users = [
    {
        "firstName": "Doreen",
        "lastName": "Duerr",
        "userName": "dduerr"
    },
    {
        "firstName": "Tom",
        "lastName": "Wirtz",
        "userName": "twirtz"
    },
    {
        "firstName": "Nadine",
        "lastName": "Eichel",
        "userName": "neichel"
    },
    {
        "firstName": "Lukas",
        "lastName": "Farber",
        "userName": "lfarber"
    },
    {
        "firstName": "Jessika",
        "lastName": "Weisz",
        "userName": "jweisz"
    },
    {
        "firstName": "Patrick",
        "lastName": "Gerber",
        "userName": "pgerber"
    },
    {
        "firstName": "Tim",
        "lastName": "Fuhrmann",
        "userName": "tfuhrmann"
    },
    {
        "firstName": "Kevin",
        "lastName": "Scholz",
        "userName": "kscholz"
    },
    {
        "firstName": "Ulrike",
        "lastName": "Freytag",
        "userName": "ufreytag"
    },
    {
        "firstName": "Thomas",
        "lastName": "Moeller",
        "userName": "tmoeller"
    },
    {
        "firstName": "Martin",
        "lastName": "Kaufmann",
        "userName": "mkaufmann"
    },
    {
        "firstName": "Robert",
        "lastName": "Pfeiffer",
        "userName": "rpfeiffer"
    },
    {
        "firstName": "Klaus",
        "lastName": "Ostermann",
        "userName": "kostermann"
    },
    {
        "firstName": "Vanessa",
        "lastName": "Krueger",
        "userName": "vkrueger"
    },
    {
        "firstName": "Steffen",
        "lastName": "Papst",
        "userName": "spapst"
    },
    {
        "firstName": "Eric",
        "lastName": "Gottlieb",
        "userName": "egottlieb"
    },
    {
        "firstName": "Simone",
        "lastName": "Neumann",
        "userName": "sneumann"
    },
    {
        "firstName": "Marko",
        "lastName": "Frankfurter",
        "userName": "mfrankfurter"
    },
    {
        "firstName": "Stephanie",
        "lastName": "Eggers",
        "userName": "seggers"
    },
    {
        "firstName": "Paul",
        "lastName": "Metzger",
        "userName": "pmetzger"
    },
    {
        "firstName": "Uta",
        "lastName": "Hartmann",
        "userName": "uhartmann"
    },
    {
        "firstName": "Dieter",
        "lastName": "Ehrlichmann",
        "userName": "dehrlichmann"
    },
    {
        "firstName": "Jan",
        "lastName": "Lehmann",
        "userName": "jlehmann"
    },
    {
        "firstName": "Dominik",
        "lastName": "Bachmeier",
        "userName": "dbachmeier"
    },
    {
        "firstName": "Kathrin",
        "lastName": "Schmidt",
        "userName": "kschmidt"
    },
]

from configuration import Configuration
import password
from random import randint, sample

def generate_identities(conf) -> Configuration:
    identities = sample(users, randint(7, 13))
    for identity in identities:
        identity["root"] = True if conf.gacha.pull(20) else False

        # Generate password: Insecure: 15%
        if conf.gacha.pull(15, True):
            identity["password"] = password.insecure_password()
            conf.flags.append(identity["password"])
        else:
            identity["password"] = password.secure_password()

        # Create account
        conf.install_script += f"""
useradd -m -d /home/{identity["userName"]} -s /bin/bash {identity["userName"]}
echo '{identity["userName"]}:{identity["password"]}' | chpasswd
"""

        # Create DB account if database is present
        db_options = ""
        if conf.conf_dict["database"]["application"] == "mysql" or conf.conf_dict["database"]["application"] == "mariadb":
            identity["dbUserExists"] = True

            if conf.gacha.pull(20): #With granting option (20%)
                db_options = " WITH GRANT OPTION"
                identity["dbWithGrantOption"] = True
            else:
                identity["dbWithGrantOption"] = False
        else:
            identity["dbUserExists"] = False


        if conf.conf_dict["database"]["application"] == "mysql":
            conf.install_script += f"""
mysql -u root -p{conf.conf_dict["database"]["root_password"]} -e "CREATE USER '{identity["userName"]}'@'%' IDENTIFIED BY '{identity["password"]}'; GRANT ALL PRIVILEGES ON *.* TO '{identity["userName"]}'@'%' {db_options}; FLUSH PRIVILEGES;"
            """
        elif conf.conf_dict["database"]["application"] == "mariadb":
            conf.install_script += f"""
mysql -u root -e "CREATE USER '{identity["userName"]}'@'%' IDENTIFIED BY '{identity["password"]}'; GRANT ALL PRIVILEGES ON *.* TO '{identity["userName"]}'@'%' {db_options}; FLUSH PRIVILEGES;"
            """

        if identity["root"] == True:
            conf.install_script += f"""
usermod -a -G sudo {identity["userName"]}
            """

    # Add identities to configuration
    conf.conf_dict["identities"] = identities

    return conf
        
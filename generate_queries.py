"""
This script allows to quickly collect all flags from the SUASploitable data center machines (except basic).
To do so, you have to put all the flag files in a following tree structure:

├── matrikel
│   ├── cloud
│   │   └── flags.txt
│   ├── cms
│   │   └── flags.txt
│   └── devbox
│       └── flags.txt
├── db_statements.txt
└── generate_queries.py

You can put there as many matrikel directories as you need.
Then run this script. Afterwards you get a file called db_statements.txt.
This file containes the statements to run in the SUASecLab's database to add the flags to the users.
Note 1: When running this script, you need the UUIDs of the students accounts. These must match the matrikel numbers.
Note 2: Besides the matrikel directories, the directory you place this script in is only allowed to have a .git directory.
        Having other directories in the root of this script will lead to errors.
"""

import os

# Get all directories
directories = os.listdir()
directories.remove(".git")
directories.remove("generate_queries.py")
if "db_statements.txt" in directories:
    directories.remove("db_statements.txt")

db_statements = []
all_flags = []

for directory in directories:
    uuid = input(f"Enter UUID for user with Matrikel {directory}: ")
    uuid = uuid.strip()

    flags = []

    for root, directories, files in os.walk(directory):
        for file in files:
            if file.endswith("flags.txt"):
                with open(os.path.join(root, file)) as flags_file:
                    for line in flags_file:
                        flags.append(f"exam-{line.strip()}")

    db_statements.append(f"""db.users.updateOne(
    {{"uuid": "{uuid}"}},
    {{ $push: {{ "availableFlags": {{ $each: {flags}}}}}}}
)
    """)
    all_flags.extend(flags)

# Collect all flags
all_flags = set(all_flags)

add_flags_statement = "db.ctf.insertMany(["
for flag in all_flags:
    add_flags_statement += (f"""
    {{
        "flag": "{flag}",
        "type": "exam",
        "description": "Exam flag"
    }},""")
add_flags_statement += "\r\n])"
db_statements.append(add_flags_statement)

with open("db_statements.txt", "w") as db_file:
    for statement in db_statements:
        db_file.write(statement)
        db_file.write("\r\n")
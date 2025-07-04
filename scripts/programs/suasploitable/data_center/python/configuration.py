#!/bin/env python3

from collections import defaultdict
from dataclasses import dataclass
from gacha import Gacha
import yaml

def convert_to_dict(d):
    if isinstance(d, defaultdict):
        d = {k: convert_to_dict(v) for k, v in d.items()}
    elif isinstance(d, dict):
        d = {k: convert_to_dict(v) for k, v in d.items()}
    return d

class Configuration():
    def __init__(self):
        self.gacha = Gacha()
        self.flags = []
        self.conf_dict = self.nested_dict()
        self.install_script = ""
    
    def nested_dict(self):
        return defaultdict(self.nested_dict)

    def write_configuration(self):
        with open("/tmp/configuration.yaml", "w") as configuration_file:
            self.conf_dict["number_of_attack_paths"] = str(self.gacha.attack_paths)
            self.yaml_dict = convert_to_dict(self.conf_dict)
            yaml.safe_dump(self.yaml_dict, configuration_file, sort_keys=True)
            
        with open("/tmp/flags.txt", "w") as flags_file:
            flags_file.write('\n'.join(self.flags))

        with open ("/tmp/install_script.sh", "w") as install_script:
            install_script.write("""#!/bin/bash \r\n""" + self.install_script)
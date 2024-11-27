#!/bin/env python

def readFile(prefix, filename):
    result = []
    # Add prefix to all lines, add result to the array above
    try:
        with open(filename, 'r') as lines:
            for line in lines:
                line = line.strip()
                result.append(prefix + "-" + line)
    except FileNotFoundError as e:
        print("File " + filename + " is not present! Did you build the according virtual machine?")

    return result

if __name__ == "__main__":
    # Collect and output all flags
    # It is assumed that flags are unique, if this is not the case, the flag is only created once
    result = set()
    result.update(readFile("bash", "build-kali/flags.txt"))
    result.update(readFile("suasploitable", "build-suasploitable-basic/flags.txt"))
    result.update(readFile("suasploitable", "build-suasploitable-cloud/flags.txt"))
    result.update(readFile("suasploitable", "build-suasploitable-cms/flags.txt"))
    print(list(result))
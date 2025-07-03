#!/bin/env python3
import random

with open("/tmp/500-worst-passwords.txt") as passwords:
    # Get number of lines
    nr = 0
    for line in passwords:
        nr += 1

    # Correct off-by-one
    nr -= 1
    
    # Move cursor to beginning
    passwords.seek(0)
    
    # Get random line
    nr = random.randint(0, nr)
    
    # Get password for that line
    for selection, line in enumerate(passwords):
        if selection == nr:
            print(line.strip())

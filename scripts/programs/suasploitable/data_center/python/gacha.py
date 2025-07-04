#!/bin/env python3

from random import randint

class Gacha:
    def __init__(self):
        self.pity = 0
        self.attack_paths = 0

    def pull(self, prob, isInitialAccess=False):
        if isInitialAccess and self.pity >= 3:
            self.pity = 0
            self.attack_paths += 1
            return True
        else:
            if isInitialAccess:
                self.pity += 1
            if randint(0, 99) < prob:
                if (isInitialAccess):
                    self.pity = 0
                    self.attack_paths += 1
                return True
            else:
                return False

        
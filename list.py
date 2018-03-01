#!/usr/bin/python

import sys
import os.path
import os
import errno
import optparse
import random
from itertools import izip

def main():
    files = {}
    for filename in os.listdir(os.getcwd()):
        file = open(filename, "r")
        linecount = 0
        for l in file:
            linecount += 1

        print filename + " lines: " + str(linecount) + " size: " + str(os.path.getsize(filename) / 1024) + "kb"

main()

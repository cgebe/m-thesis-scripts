#!/usr/bin/python

import sys
import os.path
import os
import errno
import optparse
import random

def main():
    parser = optparse.OptionParser()
    parser.add_option("--pair", action="store", dest="pair", type="string", help="language pair")

    try:
        assert len(sys.argv) > 1
        (options, args) = parser.parse_args(sys.argv[1:])
    except:
        parser.print_help()
        sys.exit(-1)

    if options.pair:
        print options.pair
    else:
        print "enter --pair option"
        sys.exit(-1)

    (L1, L2) = tuple(options.pair[:-1].split('-'))

    #fileL1 = open("europarl-v7."+pair+"."+L1, "r")
    #fileL2 = open("europarl-v7."+pair+"."+L2, "r")
    fileIDS = open("europarl-v7."+options.pair+".ids")


    proceedings = {}
    lines = 0
    for line in fileIDS:
        lines += 1
        id = line.split()[0].split("/")[1].split(".")[0]
        if id in proceedings.keys():
            proceedings[id] = proceedings[id] + 1
        else:
            proceedings[id] = 1
    # 2% into testset
    testsize = lines * 0.02

    # randomly access ids
    ids = list(proceedings.keys())
    random.shuffle(ids)

    testids = open("europarl-v7."+options.pair+".info", "w")
    # add now counts from ids list until testsize is reached
    size = 0
    for id in ids:
        size += proceedings[id]
        testids.write(id + " " + str(proceedings[id]) + "\n")
        if size >= testsize:
            break

    print size
    print lines

    fileIDS.close()
    testids.close()

main()

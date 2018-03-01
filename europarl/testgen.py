#!/usr/bin/python

import sys
import os.path
import os
import errno
import optparse
import random
from itertools import izip

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

    (L1, L2) = tuple(options.pair.split('-'))

    # load testids
    testinfo = open("test.info", "r")
    testids = {}
    for l in testinfo:
        testids[l.split()[0]] = l.split()[1]

    testinfo.close()

    fileL1 = open("europarl-v7."+options.pair+"."+L1, "r")
    fileL2 = open("europarl-v7."+options.pair+"."+L2, "r")
    fileIDS = open("europarl-v7."+options.pair+".ids", "r")
    outfileL1 = open("out/europarl-v7."+options.pair+"."+L1, "w")
    outfileL2 = open("out/europarl-v7."+options.pair+"."+L2, "w")
    outfileIDS = open("out/europarl-v7."+options.pair+".info", "w")
    outfileTestL1 = open("out/europarl-v7."+options.pair+"-test."+L1, "w")
    outfileTestL2 = open("out/europarl-v7."+options.pair+"-test."+L2, "w")
    outfileTestIDS = open("out/europarl-v7."+options.pair+"-test.info", "w")

    testlines = 0
    trainlines = 0
    for lL1, lL2, lIDS in izip(fileL1, fileL2, fileIDS):
        lL1 = lL1.strip()
        lL2 = lL2.strip()
        lIDS = lIDS.strip()
        lineid = lIDS.split()[0].split("/")[1].split(".")[0]
        if lineid not in testids.keys():
            trainlines += 1
            outfileL1.write(lL1+"\n")
            outfileL2.write(lL2+"\n")
            outfileIDS.write(lIDS+"\n")
        else:
            testlines += 1
            outfileTestL1.write(lL1+"\n")
            outfileTestL2.write(lL2+"\n")
            outfileTestIDS.write(lIDS+"\n")

    print "train lines: " + str(trainlines)
    print "test lines: " + str(testlines)

    # close files
    fileL1.close()
    fileL2.close()
    fileIDS.close()
    outfileL1.close()
    outfileL2.close()
    outfileIDS.close()
    outfileTestL1.close()
    outfileTestL2.close()
    outfileTestIDS.close()

main()

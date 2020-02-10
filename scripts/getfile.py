#!/usr/bin/env python

from __future__ import print_function
import sys
import samweb_cli

samweb = samweb_cli.SAMWebClient(experiment='dune')

files = samweb.listFiles("run_number %s " % (sys.argv[1]) + "and run_type protodune-sp and data_tier raw")

#print files
for file in files:
    #print file
    events = samweb.getURL('/files/metadata/event_numbers', {'file_name': file}).json()
    if int(sys.argv[2]) in events :
        print (file, '--nskip',events.index(int(sys.argv[2])))


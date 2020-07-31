#!/usr/bin/env python
import sys, getopt
import os
from subprocess import Popen, PIPE
import json
import argparse

argparser = argparse.ArgumentParser('Parse arguments')
argparser.add_argument('--infile',help='path to input file',required=True,type=str)
argparser.add_argument('--declare',help='validate and declare the metadata for the file specified in --infile to SAM',action='store_true')
argparser.add_argument('--appname',help='Optional override of application name for SAM metadata',type=str)
argparser.add_argument('--appversion',help='Optional override of application version for SAM metadata',type=str)
argparser.add_argument('--appfamily',help='Optional override of application family for SAM metadata',type=str)
argparser.add_argument('--campaign',help='Optional override for DUNE.campaign for SAM metadata',type=str)
argparser.add_argument('--data_stream',help='Optional override for data_stream for SAM metadata',type=str)
argparser.add_argument('--strip_parents',help='Do not include the file\'s parents in SAM metadata for declaration',action="store_true")
argparser.add_argument('--no_crc',help='Leave the crc out of the generated json',action="store_true")
argparser.add_argument('--input_json',help='Input json file containing metadata to be added to output (can contain ANY valid SAM metadata parameters)',type=str)
argparser.add_argument('--file_format',help='Value of file_format set in output md, default is binary',type=str,default='binary')
argparser.add_argument('--data_tier',help='Value of data_tier set in output md, default is pandora_info',type=str,default='pandora_info')
argparser.add_argument('--requestid',help='Value of DUNE.requestid set in output md',type=str) 

global args
args = argparser.parse_args()

#make some skeleton output
outmd = {}

#check that the input file actually exists and bail out if it doesn't
if not os.path.exists(args.infile):
    print('Error: input file %s not found. Exiting.' % args.infile)
    sys.exit(1)

if args.input_json:
    if os.path.exists(args.input_json):
        try:
            injson=open(args.input_json)
            outmd = json.load(injson)
        except:
            print('Error loading input json file.')
            raise
    else:
        print('Error, specified input file does not exist.')
        sys.exit(1)

# now everything is the same as whatever is in the input jsooon file. Obviously we need to replace some thingss like file name, size, and checkssum at a minumum. We can also strip parents if that is preferred.

outmd['file_name'] = os.path.basename(args.infile)
outmd['file_format'] = args.file_format
outmd['data_tier'] = args.data_tier
outmd['file_size'] = os.path.getsize(args.infile)

#kill the existing checksum and file_id values, if set, because they would correspond to 
# the value from the input json, which is from another file.

for ikey in [ 'crc', 'checksum', 'file_id' ]:
    if ikey in list(outmd.keys()):
        del outmd[ikey]

# Check optional overrides
if args.campaign:
    outmd['DUNE.campaign'] = args.campaign
if args.data_stream:
    outmd['data_stream'] = args.data_stream
if args.strip_parents and 'parents' in list(outmd.keys()):
    del outmd['parents']

if args.appname and args.appfamily and args.appversion:
    outmd['application'] = { 'family' : args.appfamily, 'name' : args.appname, 'version' : args.appversion }
elif args.appname or args.appfamily or args.appversion:
    print('Error: you specified at least one of --appfamily, --appname, or --appversion, but not all three. You must specify all or none of them (if none, you will get the existing values in the input json file, if you supplied one.')
    sys.exit(1)

if args.requestid != None:
    outmd['DUNE.requestid'] = args.requestid

mdtext = json.dumps(outmd, indent=2, sort_keys=True)

if args.declare:
    import ifdh
    ih = ifdh.ifdh()
    try:
        ih.declareFile(mdtext)
    except:
        print('Error declaring file. Please check!')

print(mdtext)
sys.exit(0)

#!/bin/env python3
import cache_state 
import argparse
import os, os.path
import sys
import samweb_client as swc
import pycurl
import subprocess
import shlex
import multiprocessing as mp

def check_files(thislist, cached, pending, a):
  sam = swc.SAMWebClient("dune")
  i = 0
  for f in thislist:
    if not (i%100): print("Locating files: %i/%i"%(i, len(thislist)))
    check_file(f, sam, cached, pending, a)
    i += 1
    #locs = sam.locateFile(f)
    #for l in locs:
    #  split_path = l['full_path'].split(':')
    #  if split_path[0] == 'enstore':
    #    if args.method == "pnfs":
    #      this_cached = cache_state.is_file_online_pnfs(os.path.join(split_path[1], f))
    #      if args.verbose:
    #        print( f, "ONLINE" if this_cached else "NEARLINE")
    #      if this_cached: cached += 1
    #      break 
    #    else:
    #      qos,targetQos = cache_state.get_file_qos(c, os.path.join(split_path[1], f))
    #      if "ONLINE" in qos: cached += 1 
    #      if "disk" in targetQos: pending += 1
    #a += 1

def check_file(f, sam, cached, pending, a):
  locs = sam.locateFile(f)
  for l in locs:
    split_path = l['full_path'].split(':')
    if split_path[0] == 'enstore':
      if args.method == "pnfs":
        this_cached = cache_state.is_file_online_pnfs(
            os.path.join(split_path[1], f))
        if args.verbose:
          print( f, "ONLINE" if this_cached else "NEARLINE")
        if this_cached: cached.value += 1
        break 
      else:
        qos,targetQos = cache_state.get_file_qos(c, os.path.join(split_path[1], f))
        if "ONLINE" in qos: cached.value += 1 
        if "disk" in targetQos: pending.value += 1
  a.value += 1

examples = ''
parser= argparse.ArgumentParser(epilog=examples, formatter_class=argparse.RawDescriptionHelpFormatter)

gp = parser.add_mutually_exclusive_group()
gp.add_argument("--files",
                nargs="+",
                default=[],
                metavar="FILE",
                help="Files to consider. Can be specified as a full /pnfs path, or just the SAM filename",
)
gp.add_argument("-d", "--dataset",
                metavar="DATASET",
                dest="dataset_name",
                help="Name of the SAM dataset to check cache status of",
)
gp.add_argument("-q", "--dim",
                metavar="\"DIMENSION\"",
                dest="dimensions",
                help="sam dimensions to check cache status of",
                )

parser.add_argument("-s","--sparse", type=int, dest='sparse',help="Sparsification factor.  This is used to check only a portion of a list of files",default=1)
parser.add_argument("-ss", "--snapshot", dest="snapshot", help="[Also requires -d]  Use this snapshot ID for the dataset.  Specify 'latest' for the most recent one.")
parser.add_argument("-v","--verbose", action="store_true", dest="verbose", default=False, help="Print information about individual files")
parser.add_argument("-p","--prestage", action="store_true", dest="prestage", default=False, help="Prestage the files specified")
parser.add_argument("-m", "--method", choices=["rest", "pnfs"], default="rest", help="Use this method to look up file status.")
parser.add_argument('-n', type=int, default=1, help='n procs')

args=parser.parse_args()

# gotta make sure you have a valid certificate.
# otherwise the results may lie...
if args.method in ("rest"):
    try:
        subprocess.check_call(shlex.split("setup_fnal_security --check"), stdout=open(os.devnull), stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError:
        print( "Your proxy is expired or missing.  Please run `setup_fnal_security` and then try again." )
        sys.exit(2)

filelist = None if args.dataset_name else args.files

sam = swc.SAMWebClient("dune")

cache_count = 0

# Figure out where we want to get our list of files from

# See if a SAM dataset was specified
filelist = []
if args.dataset_name:
  print( "Retrieving file list for SAM dataset definition name: '%s'..." % args.dataset_name, end="" )
  sys.stdout.flush()
try:
  if args.dataset_name:
    thislist = sam.listFiles(defname=args.dataset_name)
  elif len(args.files) > 0:
    thislist = args.files
  print(len(thislist))


  samlist = []
  #a = 0
  #cached = 0
  #pending = 0
  a = mp.Value('i', 0)
  cached = mp.Value('i', 0)
  pending = mp.Value('i', 0)

  c = cache_state.make_curl() if args.method == "rest" else None

  split_list = [thislist[i::args.n] for i in range(args.n)]
  procs = [
      mp.Process(target=check_files, args=(split_list[i], cached, pending, a))
      for i in range(args.n)
  ]

  for p in procs: p.start()
  for p in procs: p.join()

  #for f in thislist:
  #  if not (a%100): print("Locating files: %i/%i"%(a, len(thislist)), end='\r')
  #  locs = sam.locateFile(f)
  #  for l in locs:
  #    split_path = l['full_path'].split(':')
  #    if split_path[0] == 'enstore':
  #      if args.method == "pnfs":
  #        this_cached = cache_state.is_file_online_pnfs(os.path.join(split_path[1], f))
  #        if args.verbose:
  #          print( f, "ONLINE" if this_cached else "NEARLINE")
  #        if this_cached: cached += 1
  #        break 
  #      else:
  #        qos,targetQos = cache_state.get_file_qos(c, os.path.join(split_path[1], f))
  #        if "ONLINE" in qos: cached += 1 
  #        if "disk" in targetQos: pending += 1
  #  a += 1
  print()
  print(len(samlist))

  print("%i/%i files are cached"%(cached.value, a.value))

  #filelist = enstore_locations_to_paths(list(samlist), args.sparse) 
  print( " done." )
except Exception as e:
  print( e )
  print()
  print( 'Unable to retrieve SAM information for dataset: %s' %(args.dataset_name) )
  exit(-1)
  # Take the rest of the commandline as the filenames
  filelist = args


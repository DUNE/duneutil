#!/usr/bin/env python

import argparse
import os, os.path
import re
import shlex
import subprocess
import sys
import samweb_client as swc

BULK_QUERY_SIZE = 100
WEBDAV_HOST = "https://fndca4a.fnal.gov:2880"
PNFS_DIR_PATTERN = re.compile(r"/pnfs/(?P<area>[^/]+)")

try:
  HAVE_XROOTD = True
  import XRootD.client
except ImportError:
  print "ERROR: Could not import XRootD python bindings."
  sys.exit(1)

if HAVE_XROOTD:
  class LazyXrootDClient(object):
    """ Wrapper around an xrootd client that only opens the connection when needed """
   
    _XROOTD_FS_PROPS = set(dir(XRootD.client.FileSystem))
    
    def __init__(self, server_url="root://fndca1.fnal.gov:1094"):
      self._server_url = server_url
      self._client = None
    
    def _Load(self):
      if not self._client:
        self._client = XRootD.client.FileSystem(self._server_url)
    
    def __getattr__(self, attr):
      if attr in LazyXrootDClient._XROOTD_FS_PROPS:
        self._Load()
        return getattr(self._client, attr)
      
      raise AttributeError("'XRootD.client.FileSystem' object has no attribute '%s'" % attr)
  
  xrootd_client = LazyXrootDClient()

class ProgressBar(object):
  def __init__(self, total, announce_threshold=50):
    self.total = total
    self._total_div10 = total / 10
    
    self.announce = total >= announce_threshold
    self._last_announce_decile = -1
    
    self.Update(0)
    
  def Update(self, n):
    current_decile = None
    if self.total > 10:
      current_decile = n / self._total_div10
    if self.announce:
      if current_decile is None:
      	print " %d" % n,
      if (current_decile > self._last_announce_decile or n == self.total):  # always want to announce 100%
        curr_perc = int(float(n) / float(self.total) * 100)
        print " %d%%" % curr_perc,
      
        self._last_announce_decile = n / self._total_div10

      sys.stdout.flush()
    

def FilelistCacheCount(files, verbose_flag, METHOD="pnfs"):
  bulk_query_list = []
  
  if len(files) > 1:
    print "Checking %d files:" % len(files)
  cached = 0
  progbar = ProgressBar(len(files)) 
  n = 0
  
  for f in files:
    if METHOD in ("xrootd", "webdav"):
      f = PNFS_DIR_PATTERN.sub(r"/pnfs/fnal.gov/usr/\1", f)
    if METHOD == "xrootd":
      stat = xrootd_client.stat(f)
      if len(stat) > 0 and stat[1] is not None:
        if stat[1].flags & XRootD.client.flags.StatInfoFlags.OFFLINE == 0:
          cached += 1
      n += 1
      progbar.Update(n)
    elif METHOD == "webdav":
      bulk_query_list.append(f)
      
    else:
      path, filename = os.path.split(f)
      stat_file="%s/.(get)(%s)(locality)"%(path,filename)
      theStatFile=open(stat_file)
      state=theStatFile.readline()
      theStatFile.close()
      if 'ONLINE' in state:
        cached += 1 

      n += 1
      progbar.Update(n)
  
  if len(bulk_query_list) > 0:
    while len(bulk_query_list) > 0:
        # it's probably possible to actually implement this using urllib2 natively,
       # but I couldn't make it work very quickly
 
        params = {
          "local_cert": "/tmp/x509up_u%d"  % os.getuid(),
          "host": WEBDAV_HOST,
        }
        
        
        cmd = """
        curl  -L --capath /etc/grid-security/certificates \
             --cert %(local_cert)s \
             --cacert %(local_cert)s \
             --key %(local_cert)s \
             -s -X PROPFIND -H Depth:0 \
             --data '<?xml version="1.0" encoding="utf-8"?>
              <D:propfind xmlns:D="DAV:">
                  <D:prop xmlns:R="http://www.dcache.org/2013/webdav"
                          xmlns:S="http://srm.lbl.gov/StorageResourceManager">
                      <S:FileLocality/>
                  </D:prop>
              </D:propfind>' \
        """ % params
        for f in bulk_query_list[:BULK_QUERY_SIZE]:
          cmd += " %s/%s" % (WEBDAV_HOST, f)
          
        out = subprocess.check_output(shlex.split(cmd))
        cached += sum("ONLINE" in l for l in out.split("\n"))
        
        # NOTE: *not* n*BULK_QUERY_SIZE since we've already stripped off (n-1)*BULK_QUERY_SIZE in previous iterations
        bulk_query_list = bulk_query_list[BULK_QUERY_SIZE:]
        n += 1
        if len(bulk_query_list) > 0:
          progbar.Update( n*BULK_QUERY_SIZE )
  
  progbar.Update(progbar.total)
  
  return cached

verbose_flag=False

parser= argparse.ArgumentParser()

gp = parser.add_mutually_exclusive_group()
gp.add_argument("files",
                nargs="*",
                default=[],
                metavar="FILE",
                help="Files to consider",
)
gp.add_argument("-d", "--dataset",
                metavar="DATASET",
                dest="dataset_name",
                help="Name of the SAM dataset to check cache status of",
)

parser.add_argument("-s","--sparse", dest='sparse',help="Sparsification factor.  This is used to check only a portion of a list of files",default=1)
parser.add_argument("-ss", "--snapshot", dest="snapshot", help="[Also requires -d]  Use this snapshot ID for the dataset.  Specify 'latest' for the most recent one.")
parser.add_argument("-v","--verbose", action="store_true", dest="verbose", default="False", help="Print information about individual files")
parser.add_argument("-m", "--method", choices=["webdav", "xrootd", "pnfs"], default="webdav", help="Use this method to look up file status.")

args=parser.parse_args()

if args.method == "xrootd" and not HAVE_XROOTD:
  print >> sys.stderr, "XRootD requested but not available.  Choose a different --method."
  sys.exit(2)

# gotta make sure you have a valid certificate.
# otherwise the results may lie...
if args.method in ("xrootd", "webdav"):
  try:
  	subprocess.check_call(shlex.split("setup_fnal_security --check"), stdout=open(os.devnull), stderr=subprocess.STDOUT)
  except subprocess.CalledProcessError:
  	print "Your proxy is expired or missing.  Please run `setup_fnal_security` and then try again."
  	sys.exit(2)
  
METHOD = args.method

filelist = None if args.dataset_name else args.files

sam = swc.SAMWebClient("dune")

#
# Figure out where we want to get our list of files from

# See if a SAM dataset was specified
if args.dataset_name:
  print "Retrieving file list for SAM dataset definition name: '%s'..." % args.dataset_name,
  sys.stdout.flush()
  try:
    dimensions = None
    if args.snapshot == "latest":
        dimensions = "dataset_def_name_newest_snapshot %s" % args.dataset_name
    elif args.snapshot:
        dimensions = "snapshot_id %s" % args.snapshot
    if dimensions:
        samlist = sam.listFiles(dimensions=dimensions)
    else:
        samlist  = sam.listFiles(defname=args.dataset_name)
    filelist = [ f for  f in samlist[::int(args.sparse)] ]
    print " done."
  except Exception as e:
    print e
    print
    print 'Unable to retrieve SAM information for dataset: %s' %(args.dataset_name)
    exit(-1)
    # Take the rest of the commandline as the filenames
    filelist = args

cache_count = 0
miss_count = 0

n_files = len(filelist)
announce = n_files > 50  # some status notes if there are lots of files
if announce:
  print "Finding locations for %d files:" % n_files

progbar = ProgressBar(n_files) 

files_to_check = []
n = -1  # so we start at 0 below
for f in filelist:
  n += 1
  progbar.Update(n)

  if os.path.isfile(f):
    loc = os.path.split(f)[0]
    # ok.  try to guess what kind of location this is...
    if loc.startswith("/pnfs") and ("/scratch" in loc or "/persistent" in loc):
      loc = "dcache:" + loc
    elif loc.startswith("/pnfs"):
      loc = "enstore:" + loc
    elif loc.startswith("/dune"):
      loc = "bluearc:" + loc
    else:
      print >> sys.stderr, "Unknown storage tier for file:", f
      print >> sys.stderr, "Cannot determine cache state."
      sys.exit(2)
  
    loc = [loc,]
  else:
    try:
      loc = sam.locateFile(f)
      loc = [l['location'] for l in loc]
    except (swc.exceptions.FileNotFound, swc.exceptions.HTTPNotFound):
       print >> sys.stderr, "File is not known to SAM and is not a full path:", f
       sys.exit(2)
  
  # if it's got a dcache location, our tools will prefer that location anyway,
  # and that's cached by construction.
  # bluearc files are cached for the purposes of this script, I guess...
  if any(l.startswith("dcache:") or l.startswith("bluearc:") for l in loc):
    cache_count += 1
    continue

  for l in loc:
    if l.startswith("enstore:"):
      # We now have the enstore location
      # Strip off the enstore prefix and the tape label
      thePath = l.split(':')[1].split('(')[0]
      files_to_check.append(os.path.join(thePath, f))

progbar.Update(progbar.total)
print

non_enstore = cache_count

cache_count = FilelistCacheCount(files_to_check, verbose_flag, METHOD)
miss_count = len(files_to_check) - cache_count

cache_count += non_enstore

total = float(cache_count + miss_count)
cache_frac_str = (" (%d%%)" % round(cache_count/total*100)) if total > 0 else ""
miss_frac_str = (" (%d%%)" % round(miss_count/total*100)) if total > 0 else ""

if total > 1:
  print
  print "Cached: %d%s\tTape only: %d%s" % (cache_count, cache_frac_str, miss_count, miss_frac_str)
elif total == 1:
  print "CACHED" if cache_count > 0 else "NOT CACHED"

if miss_count == 0:
  sys.exit(0)
else:
  sys.exit(1)

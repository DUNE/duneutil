#!/usr/bin/env python

import sys
import json
import samweb_client as swc

def update_info(flist, md):
    nfiles = len(flist)
    ith = 0
    for f in flist:
        sys.stdout.write("{}/{} Updating Metadata for: {}\n".format(ith, nfiles, f))
        sys.stdout.flush()
        sam.modifyFileMetadata(f,md)
        ith += 1
    print("-- Done")
    return


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(
            prog='update_metadata.py',
            description="Update one metadata field for multiple files matching SAM dimensions.",
            epilog="")
    parser.add_argument('-d', '--dimensions', type=str, help="SAM dimensions")
    parser.add_argument('-m', '--metadata', type=json.loads, help="metadata to be updated")
    parser.add_argument('-f', '--filejson', type=string, help="Json file containing metadata to be updated")
    args = parser.parse_args()

    sam = swc.SAMWebClient("dune")

    flist=sam.listFiles(args.dimensions)
    print("%d files matching dimension." % (len(flist)))
    if args.metadata is not None:
        update_info(flist, args.metadata)
        return
    if args.metadata is None and args.file is not None:
        with open(args.filejson) as fjson:
            update_info(flist, json.loads(fjson))
        return

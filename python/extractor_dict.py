#!/usr/bin/env python

from __future__ import print_function

import sys, getopt
import os
from subprocess import Popen, PIPE
import threading
import queue
import project_utilities, root_metadata
import json
import abc

# Function to wait for a subprocess to finish and fetch return code,
# standard output, and standard error.
# Call this function like this:
#
# q = Queue.Queue()
# jobinfo = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
# wait_for_subprocess(jobinfo, q)
# rc = q.get()      # Return code.
# jobout = q.get()  # Standard output
# joberr = q.get()  # Standard error

"""extractor_dict.py
Purpose: To extract metadata from output file on worker node, generate JSON file
"""


class MetaData(object):
    """Base class to hold / interpret general metadata"""
    __metaclass__ = abc.ABCMeta

    @abc.abstractmethod
    def __init__(self, inputfile):
        self.inputfile = inputfile

    def extract_metadata_to_pipe(self):
        """Extract metadata from inputfile into a pipe for further processing."""
        local = project_utilities.path_to_local(self.inputfile)
        if len(local) > 0:
            proc = Popen(["sam_metadata_dumper", local], stdout=PIPE,
                         stderr=PIPE)
        else:
            url = project_utilities.path_to_url(inputfile)
            proc = Popen(["sam_metadata_dumper", url], stdout=PIPE,
                         stderr=PIPE)
        if len(local) > 0 and local != self.inputfile:
            os.remove(local)
        return proc
    
    def get_job(self, proc):
        """Run the proc in a 60-sec timeout queue, return stdout, stderr"""
        q = queue.Queue()
        thread = threading.Thread(target=self.wait_for_subprocess, args=[proc, q])
        thread.start()
        thread.join(timeout=60)
        if thread.is_alive():
            print('Terminating subprocess because of timeout.')
            proc.terminate()
            thread.join()
        rc = q.get()
        jobout = q.get()
        joberr = q.get()
        if rc != 0:
            raise RuntimeError('sam_metadata_dumper returned nonzero exit status {}.'.format(rc))
        return jobout, joberr
    
    @staticmethod
    def wait_for_subprocess(jobinfo, q):
        """Run jobinfo, put the return code, stdout, and stderr into a queue"""
        jobout, joberr = jobinfo.communicate()
        rc = jobinfo.poll()
        for item in (rc, jobout, joberr):
            q.put(item)
        return

    @staticmethod
    def mdart_gen(jobtuple):
        """Take Jobout and Joberr (in jobtuple) and return mdart object from that"""
        mdtext = ''.join(line.replace(", ,", ",") for line in jobtuple[0].split('\n') if line[-3:-1] != ' ,')
        mdtop = json.JSONDecoder().decode(mdtext)
        if len(mdtop.keys()) == 0:
            print('No top-level key in extracted metadata.')
            sys.exit(1)
        file_name = mdtop.keys()[0]
        return mdtop[file_name]

    @staticmethod
    def md_handle_application(md):
        """If there's no application key in md dict, create the key with a blank dictionary.
        Then return md['application'], along with mdval"""
        if 'application' not in md:
            md['application'] = {}
        return md['application']


class expMetaData(MetaData):
    """Class to hold/interpret experiment-specific metadata"""
    def __init__(self, expname, inputfile):
        MetaData.__init__(self, inputfile)
        self.expname = expname
        #self.exp_md_keyfile = expname + '_metadata_key'
        try:
            #translateMetaData = __import__("experiment_utilities", "MetaDataKey")
            from experiment_utilities import MetaDataKey
        except ImportError:
            print("You have not defined an experiment-specific metadata and key-translating module in experiment_utilities. Exiting")
            raise

        metaDataModule = MetaDataKey()
        self.metadataList, self.translateKeyf = metaDataModule.metadataList(), metaDataModule.translateKey

    def translateKey(self, key):
        """Returns the output of the imported translateKey function (as translateKeyf) called on key"""
        return self.translateKeyf(key)

    def md_gen(self, mdart, md0={}):
        """Loop through art metdata, generate metadata dictionary"""
        # define an empty python dictionary which will hold sam metadata.
        # Some fields can be copied directly from art metadata to sam metadata.
        # Other fields require conversion.
        md = {}

        # Loop over art metadata.
        for mdkey in mdart.keys():
            mdval = mdart[mdkey]

            # Skip some art-specific fields.

            if mdkey == 'file_format_version':
                pass
            elif mdkey == 'file_format_era':
                pass

            # Ignore primary run_type field (if any).
            # Instead, get run_type from runs field.

            elif mdkey == 'run_type':
                pass

            # Ignore data_stream for now.

            elif mdkey == 'data_stream':
                pass

            # Ignore process_name for now.

            elif mdkey == 'process_name':
                pass

            # Application family/name/version.

            elif mdkey == 'applicationFamily':
                if not md.has_key('application'):
                    md['application'] = {}
                md['application']['family'] = mdval
            elif mdkey == 'StageName':
                if not md.has_key('application'):
                    md['application'] = {}
                md['application']['name'] = mdval
            elif mdkey == 'applicationVersion':
                if not md.has_key('application'):
                    md['application'] = {}
                md['application']['version'] = mdval

            # Parents.

            elif mdkey == 'parents':
                mdparents = []
                for parent in mdval:
                    parent_dict = {'file_name': parent}
                    mdparents.append(parent_dict)
                md['parents'] = mdparents

            # Other fields where the key or value requires minor conversion.

            elif mdkey == 'first_event':
                md[mdkey] = mdval[2]
            elif mdkey == 'last_event':
                md[mdkey] = mdval[2]
            elif mdkey == 'lbneMCGenerators':
                md['lbne_MC.generators']  = mdval
            elif mdkey == 'lbneMCOscillationP':
                md['lbne_MC.oscillationP']  = mdval
            elif mdkey == 'lbneMCTriggerListVersion':
                md['lbne_MC.trigger-list-version']  = mdval
            elif mdkey == 'lbneMCBeamEnergy':
                md['lbne_MC.beam_energy']  = mdval
            elif mdkey == 'lbneMCBeamFluxID':
                md['lbne_MC.beam_flux_ID']  = mdval
            elif mdkey == 'lbneMCName':
                md['lbne_MC.name']  = mdval
            elif mdkey == 'lbneMCDetectorType':
                md['lbne_MC.detector_type']  = mdval
            elif mdkey == 'lbneMCNeutrinoFlavors':
                md['lbne_MC.neutrino_flavors']  = mdval
            elif mdkey == 'lbneMCMassHierarchy':
                md['lbne_MC.mass_hierarchy']  = mdval
            elif mdkey == 'lbneMCMiscellaneous':
                md['lbne_MC.miscellaneous']  = mdval
            elif mdkey == 'lbneMCGeometryVersion':
                md['lbne_MC.geometry_version']  = mdval
            elif mdkey == 'lbneMCOverlay':
                md['lbne_MC.overlay']  = mdval
            elif mdkey == 'lbneDataRunMode':
                md['lbne_data.run_mode']  = mdval
            elif mdkey == 'lbneDataDetectorType':
                md['lbne_data.detector_type']  = mdval
            elif mdkey == 'lbneDataName':
                md['lbne_data.name']  = mdval

            # For all other keys, copy art metadata directly to sam metadata.
            # This works for run-tuple (run, subrun, runtype) and time stamps.

            else:
                md[mdkey] = mdart[mdkey]


	# Get the other meta data field parameters
        md['file_name'] = self.inputfile.split("/")[-1]
        if 'file_size' in md0:
            md['file_size'] = md0['file_size']
        else:
            md['file_size'] = os.path.getsize(self.inputfile)
        if 'crc' in md0:
            md['crc'] = md0['crc']
        else:
            md['crc'] = root_metadata.fileEnstoreChecksum(self.inputfile)

        # In case we ever want to check out what md is for any instance of MetaData by calling instance.md
        self.md = md
        return self.md

    def getmetadata(self, md0={}):
        """ Get metadata from input file and return as python dictionary.
        Calls other methods in class and returns metadata dictionary"""
        proc = self.extract_metadata_to_pipe()
        jobt = self.get_job(proc)
        mdart = self.mdart_gen(jobt)
        return self.md_gen(mdart, md0)	

def main():
    try:
        expSpecificMetadata = expMetaData(os.environ['SAM_EXPERIMENT'], str(sys.argv[1]))
    except TypeError:
        print('You have not implemented a defineMetaData function by providing an experiment.')
        print('No metadata keys will be saved')
        raise
    mdtext = json.dumps(expSpecificMetadata.getmetadata(), indent=2, sort_keys=True)
    print(mdtext)
    sys.exit(0)



if __name__ == "__main__":
    main()



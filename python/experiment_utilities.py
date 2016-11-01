#!/usr/bin/env python
#----------------------------------------------------------------------
#
# Name: experiment_utilities.py
#
# Purpose: A python module containing various experiment-specific
#          python utility functions.
#
# Created: 28-Oct-2013  H. Greenlee
#
#----------------------------------------------------------------------

import os
import larbatch_utilities
import subprocess

# Don't fail (on import) if samweb is not available.

try:
    import samweb_cli
except ImportError:
    pass

def get_dropbox(filename):
    
    # Get metadata.
    
    md = {}
    exp = 'dune'
    if os.environ.has_key('SAM_EXPERIMENT'):
        exp = os.environ['SAM_EXPERIMENT']
    samweb = samweb_cli.SAMWebClient(experiment=exp)
    try:
        md = samweb.getMetadata(filenameorid=filename)
    except:
        pass

    # Extract the metadata fields that we need.
    
    file_type = ''

    if md.has_key('file_type'):
        file_type = md['file_type']

    if not file_type:
        raise RuntimeError, 'Missing or invalid metadata for file %s.' % filename

    # Construct dropbox path.

    #path = '/dune/data/dunepro/dropbox/%s' % file_type
    path = '/pnfs/dune/scratch/dunepro/dropbox/%s' % file_type
    return path

# Return fcl configuration for experiment-specific sam metadata.

def get_sam_metadata(project, stage):
    result = 'services.FileCatalogMetadataDUNE: {\n'
    for key in project.parameters:
        result = result + '  %s: "%s"\n' % (key, project.parameters[key])
    for key in stage.parameters:
        result = result + '  %s: "%s"\n' % (key, stage.parameters[key])
    result = result + '  StageName: "%s"\n' % stage.name
    result = result + '}\n'
    return result

def get_ups_products():
    return 'dunetpc'

# Function to return path to the setup_dune.sh script

def get_setup_script_path():

    OASIS_DIR="/cvmfs/oasis.opensciencegrid.org/dune/products/"
    FERMIAPP_DIR="/grid/fermiapp/products/dune/"

    if os.path.isfile(FERMIAPP_DIR+"setup_dune.sh"):
        setup_script = FERMIAPP_DIR+"setup_dune.sh"
    elif os.path.isfile(OASIS_DIR+"setup_dune.sh"):
        setup_script = OASIS_DIR+"setup_dune.sh"
    else:
        raise RuntimeError, "Could not find setup script at "+FERMIAPP_DIR+" or "+OASIS_DIR

    return setup_script

# Construct dimension string for project, stage.

def dimensions(project, stage, ana=False):

    dim = 'file_type %s' % project.file_type
    dim = dim + ' and data_tier %s' % stage.data_tier
    for key in project.parameters:
        if key == 'MCName':
            dim = dim + ' and lbne_MC.name %s' % project.parameters[key]
        if key == 'DataName':
            dim = dim + ' and lbne_data.name %s' % project.parameters[key]
    dim = dim + ' and version %s' % project.release_tag
    dim = dim + ' and application %s' % stage.name
    dim = dim + ' and availability: anylocation'
    return dim

# Get grid proxy.

def get_proxy():

    global proxy_ok
    proxy_ok = False

    # Make sure we have a valid certificate.

    larbatch_utilities.test_kca()

    # Get proxy using either specified cert+key or default cert.

    if os.environ.has_key('X509_USER_CERT') and os.environ.has_key('X509_USER_KEY'):
        cmd=['voms-proxy-init',
             '-rfc',
             '-cert', os.environ['X509_USER_CERT'],
             '-key', os.environ['X509_USER_KEY'],
             '-voms', '%s:/%s/Role=%s' % (larbatch_utilities.get_experiment(), larbatch_utilities.get_experiment(), larbatch_utilities.get_role())]
        try:
            subprocess.check_call(cmd, stdout=-1, stderr=-1)
            proxy_ok = True
        except:
            pass
        pass
    else:
        cmd=['voms-proxy-init',
             '-noregen',
             '-rfc',
             '-voms',
             '%s:/%s/Role=%s' % (larbatch_utilities.get_experiment(), larbatch_utilities.get_experiment(), larbatch_utilities.get_role())]
        jobinfo = subprocess.Popen(cmd, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE)
        jobout, joberr = jobinfo.communicate()
        rc = jobinfo.poll()
        if rc != 0 and rc!= 1:
            proxy_ok = False
        else:
            proxy_ok = True
    # Done

    return proxy_ok

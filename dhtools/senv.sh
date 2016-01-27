#!/bin/sh

# source this file to setup the DUNE environment for copying files -- needed so we
# have access to root, the right version of python, and samweb

source /grid/fermiapp/products/dune/setup_dune.sh
setup dunetpc v04_29_00 -q e9:prof

# sam web client is already set up
# now using a service certificate
# kx509

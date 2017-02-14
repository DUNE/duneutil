# Source this file to set the basic configuration needed by LArSoft 
# and for the DUNE-specific software that interfaces to LArSoft.

FERMIAPP_LARSOFT_DIR="/grid/fermiapp/products/larsoft/"
FERMIOSG_LARSOFT_DIR="/cvmfs/fermilab.opensciencegrid.org/products/larsoft/"
#OASIS_LARSOFT_DIR="/cvmfs/oasis.opensciencegrid.org/fermilab/products/larsoft/"

FERMIAPP_DUNE_DIR="/grid/fermiapp/products/dune/"
FERMIOSG_DUNE_DIR="/cvmfs/dune.opensciencegrid.org/products/dune/"
#OASIS_DUNE_DIR="/cvmfs/oasis.opensciencegrid.org/lbne/products"

DUNE_BLUEARC_DATA="/dune/data/"

# Set up ups for LArSoft
# Sourcing this setup will add larsoft and common to $PRODUCTS

for dir in $FERMIOSG_LARSOFT_DIR $FERMIAPP_LARSOFT_DIR;
do
  if [[ -f $dir/setup ]]; then
    echo "Setting up larsoft UPS area... ${dir}"
    source $dir/setup
    common=`dirname $dir`/common/db
    if [[ -d $common ]]; then
      export PRODUCTS=`dropit -p $PRODUCTS common/db`:`dirname $dir`/common/db
    fi
    break
  fi
done

# Set up ups for DUNE

for dir in $FERMIOSG_DUNE_DIR $FERMIAPP_DUNE_DIR;
do
  if [[ -f $dir/setup ]]; then
    echo "Setting up DUNE UPS area... ${dir}"
    source $dir/setup
    break
  fi
done

# Add current working directory (".") to FW_SEARCH_PATH
#
if [[ -n "${FW_SEARCH_PATH}" ]]; then
  FW_SEARCH_PATH=`dropit -e -p $FW_SEARCH_PATH .`
  FW_SEARCH_PATH=`dropit -e -p $FW_SEARCH_PATH /grid/fermiapp/lbne/lar/aux`
  export FW_SEARCH_PATH=.:/grid/fermiapp/lbne/lar/aux:${FW_SEARCH_PATH}
else
  export FW_SEARCH_PATH=.:/grid/fermiapp/lbne/lar/aux
fi

# Add DUNE data path to FW_SEARCH_PATH
#
if [[ -d "${DUNE_BLUEARC_DATA}" ]]; then

    if [[ -n "${FW_SEARCH_PATH}" ]]; then
      FW_SEARCH_PATH=`dropit -e -p $FW_SEARCH_PATH ${DUNE_BLUEARC_DATA}`
      export FW_SEARCH_PATH=${DUNE_BLUEARC_DATA}:${FW_SEARCH_PATH}
    else
      export FW_SEARCH_PATH=${DUNE_BLUEARC_DATA}
    fi

fi

# Set up the basic tools that will be needed
#
if [ `uname` != Darwin ]; then

  # Work around git table file bugs.

  export PATH=`dropit git`
  export LD_LIBRARY_PATH=`dropit -p $LD_LIBRARY_PATH git`
  setup git
fi
setup gitflow
setup mrb
setup pycurl
# Define the value of MRB_PROJECT. This can be used
# to drive other set-ups. 
# We need to set this to 'larsoft' for now.

export MRB_PROJECT=larsoft

# Define environment variables that store the standard experiment name.

export JOBSUB_GROUP=dune
export EXPERIMENT=dune     # Used by ifdhc
export SAM_EXPERIMENT=dune

# For Art workbook

export ART_WORKBOOK_OUTPUT_BASE=/dune/data/users
export ART_WORKBOOK_WORKING_BASE=/dune/app/users
export ART_WORKBOOK_QUAL="s2:e5:nu"

# For database

export DBIWSPWDFILE=/dune/experts/path/to/proddbpwd/for/writes
export DBIWSURL=http://dbdata0vm.fnal.gov:8116/LBNE35tCon/app/
export DBIWSURLINT=http://dbdata0vm.fnal.gov:8116/LBNE35tCon/app/
export DBIWSURLPUT=http://dbdata0vm.fnal.gov:8117/LBNE35tCon/app/
export DBIQEURL=http://dbdata0vm.fnal.gov:8122/QE/dune35t/prod/app/SQ/
export DBIHOST=ifdbprod.fnal.gov
export DBINAME=dune35t_prod
export DBIPORT=5442
export DBIUSER=dune_reader
export DBIPWDFILE=~jpaley/dune/db/proddbpwd

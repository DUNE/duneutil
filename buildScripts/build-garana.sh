#!/bin/bash

# build garana
# use mrb
# designed to work on Jenkins
# this is a proof of concept script

# Chris Hilgenberg 8 April 2021
# copied from garsoft build script, originally written by Tom Junk

echo "Entering script: " $0
cat /etc/os-release

if [[ `grep PRETTY /etc/os-release | grep "Scientific Linux 7"`x = x ]]; then
    echo "Need SL7 -- starting a container with apptainer"
    /cvmfs/oasis.opensciencegrid.org/mis/apptainer/current/bin/apptainer run -B /cvmfs /cvmfs/singularity.opensciencegrid.org/fermilab/fnal-dev-sl7:latest $0
    exit $?
fi

echo "garana version: $GARANA_VERSION"
echo "target qualifier: $QUAL"
echo "build type: $BUILDTYPE"
echo "workspace: $WORKSPACE"

# Don't do ifdh build on macos.

#if uname | grep -q Darwin; then
#  if ! echo $QUAL | grep -q noifdh; then
#    echo "Ifdh build requested on macos.  Quitting."
#    exit
#  fi
#fi

# Get number of cores to use.

if [ `uname` = Darwin ]; then
  #ncores=`sysctl -n hw.ncpu`
  #ncores=$(( $ncores / 4 ))
  ncores=4
else
  ncores=`cat /proc/cpuinfo 2>/dev/null | grep -c -e '^processor'`
fi
if [ $ncores -lt 1 ]; then
  ncores=1
fi
echo "Building using $ncores cores."

# Environment setup, uses cvmfs.

echo "ls /cvmfs/dune.opensciencegrid.org/products/dune/"
ls /cvmfs/dune.opensciencegrid.org/products/dune/
echo

echo "ls /cvmfs/larsoft.opensciencegrid.org/products/"
ls /cvmfs/larsoft.opensciencegrid.org/products/
echo

echo "ls /cvmfs/fermilab.opensciencegrid.org/products/common/db"
ls /cvmfs/fermilab.opensciencegrid.org/products/common/db
echo

if [ `uname` = Darwin -a -f /grid/fermiapp/products/dune/setup_dune_fermiapp.sh ]; then
  source /grid/fermiapp/products/dune/setup_dune_fermiapp.sh || exit 1
elif [ -f /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh ]; then
  if [ -x /cvmfs/grid.cern.ch/util/cvmfs-uptodate ]; then
    /cvmfs/grid.cern.ch/util/cvmfs-uptodate /cvmfs/dune.opensciencegrid.org/products
  fi
  source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh || exit 1
else
  echo "No setup file found."
  exit 1
fi

# skip around a version of mrb that does not work on macOS

if [ `uname` = Darwin ]; then
  if [[ x`which mrb | grep v1_17_02` != x ]]; then
    unsetup mrb || exit 1
    setup mrb v1_16_02 || exit 1
  fi
fi

# Use system git on macos.

if ! uname | grep -q Darwin; then
  setup git || exit 1
fi
setup gitflow || exit 1
export MRB_PROJECT=dune
#echo "Mrb path:"
#which mrb

#dla set -x
rm -rf $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/copyBack || exit 1
rm -f $WORKSPACE/copyBack/* || exit 1
cd $WORKSPACE/temp || exit 1

FQUAL=${QUAL}:${BUILDTYPE}

mrb newDev -v $GARANA_VERSION -q $FQUAL || exit 1

#dla set +x
source localProducts*/setup || exit 1

#echo "Chris MRB_SOURCE: ${MRB_SOURCE}"
#echo "Chris MRB_BUILDDIR: ${MRB_BUILDDIR}"

# some shenanigans so we can use getopt v1_1_6
if [ `uname` = Darwin ]; then
#  cd $MRB_INSTALL
#  curl --fail --silent --location --insecure -O http://scisoft.fnal.gov/scisoft/packages/getopt/v1_1_6/getopt-1.1.6-d13-x86_64.tar.bz2 || \
#      { cat 1>&2 <<EOF
#ERROR: pull of http://scisoft.fnal.gov/scisoft/packages/getopt/v1_1_6/getopt-1.1.6-d13-x86_64.tar.bz2 failed
#EOF
#        exit 1
#      }
#  tar xf getopt-1.1.6-d13-x86_64.tar.bz2 || exit 1
  setup getopt v1_1_6  || exit 1
#  which getopt
fi

#dla set -x
cd $MRB_SOURCE  || exit 1
# check out a readonly version
#mrb g -r -t $GARANA_VERSION -d garana garana-garana || exit 1
#mrb g -r -t $GARANA_VERSION garana || exit 1
mrb g -r -t $GARANA_VERSION https://www.github.com/DUNE/garana || exit 
cd $MRB_BUILDDIR || exit 1
ls
mrbsetenv || exit 1
mrb b -D BUILD_W_CET=ON -j$ncores || exit 1
mrb mp -n garana -- -j$ncores || exit 1

# Extract flavor.

flvr=''
if uname | grep -q Darwin; then
  flvr=`ups flavor -2`
else
  flvr=`ups flavor -4`
fi


# Save artifacts.

mv *.bz2  $WORKSPACE/copyBack/ || exit 1

ls -l $WORKSPACE/copyBack/
cd $WORKSPACE || exit 1
rm -rf $WORKSPACE/temp || exit 1

#dla set +x

exit 0

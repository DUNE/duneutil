#!/bin/bash

# build duneanaobj
# use mrb
# designed to work on Jenkins

# Tom Junk, July 22, 2021

echo "duneanaobj version: $DUNEANAOBJ_VERSION"
echo "target qualifier (input): $QUAL"
echo "build type: $BUILDTYPE"
QUAL=`echo ${QUAL} | sed -e "s/-/:/g"`
FQUAL=${QUAL}:${BUILDTYPE}
echo "Full qualifier: $FQUAL"
echo "workspace: $WORKSPACE"

# Get number of cores to use.

ncores=`cat /proc/cpuinfo 2>/dev/null | grep -c -e '^processor'`
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

if [ -f /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh ]; then
  if [ -x /cvmfs/grid.cern.ch/util/cvmfs-uptodate ]; then
    /cvmfs/grid.cern.ch/util/cvmfs-uptodate /cvmfs/dune.opensciencegrid.org/products
  fi
  source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh || exit 1
else
  echo "No setup file found."
  exit 1
fi

setup gitflow || exit 1
export MRB_PROJECT=dune
echo "Mrb path:"
which mrb

rm -rf $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/copyBack || exit 1
rm -f $WORKSPACE/copyBack/* || exit 1
cd $WORKSPACE/temp || exit 1

mrb newDev -v $DUNEANAOBJ_VERSION -q $FQUAL || exit 1

source localProducts*/setup || exit 1

cd $MRB_SOURCE  || exit 1
mrb g --repo-type github --github-org dune -r -t $DUNEANAOBJ_VERSION  duneanaobj || exit 1

#patch buggy CMakeLists.txt files

if [ $DUNEANAOBJ_VERSION = v02_04_00 ]; then
  sed -i -e "s@duneanaobj/StandardRecord/Proxy/SRProxy@duneanaobj/duneanaobj/StandardRecord/Proxy/SRProxy@" duneanaobj/duneanaobj/StandardRecord/Proxy/CMakeLists.txt
  sed -i -e "s@duneanaobj/StandardRecord/Proxy/FwdDeclare@duneanaobj/duneanaobj/StandardRecord/Proxy/FwdDeclare@" duneanaobj/duneanaobj/StandardRecord/Proxy/CMakeLists.txt
  sed -i -e "s@duneanaobj/StandardRecord/Flat/FlatRecord@duneanaobj/duneanaobj/StandardRecord/Flat/FlatRecord@" duneanaobj/duneanaobj/StandardRecord/Flat/CMakeLists.txt
  sed -i -e "s@duneanaobj/StandardRecord/Flat/FwdDeclare@duneanaobj/duneanaobj/StandardRecord/Flat/FwdDeclare@" duneanaobj/duneanaobj/StandardRecord/Flat/CMakeLists.txt
fi

cd $MRB_BUILDDIR || exit 1
mrbsetenv || exit 1
mrb b -j$ncores || exit 1
mrb mp -n duneanaobj -- -j$ncores || exit 1

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


exit 0

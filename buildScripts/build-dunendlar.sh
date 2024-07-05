#!/bin/bash

# build dunendlar
# trj Oct 31, 2019
# use mrb
# designed to work on Jenkins

echo "Entering script: " $0
cat /etc/os-release

if [[ `grep PRETTY /etc/os-release | grep "Scientific Linux 7"`x = x ]]; then
    echo "Need SL7 -- starting a container with apptainer"
    /cvmfs/oasis.opensciencegrid.org/mis/apptainer/current/bin/apptainer run -B /cvmfs /cvmfs/singularity.opensciencegrid.org/fermilab/fnal-dev-sl7:latest $0
    exit $?
fi
export UPS_OVERRIDE="-H Linux64bit+3.10-2.17"

echo "dunendlar version: $VERSION"
echo "base qualifiers: $QUAL"
QUAL=`echo ${QUAL} | sed -e "s/-/:/g"`
echo "modified base qualifiers: $QUAL"
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

# use /grid/fermiapp for macOS builds and cvmfs for Linux

echo "ls /cvmfs/dune.opensciencegrid.org/products/dune/"
ls /cvmfs/dune.opensciencegrid.org/products/dune/
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

# Use git out of ups except use the system git on macos

if ! uname | grep -q Darwin; then
  setup git || exit 1
fi

# skip around a version of mrb that does not work on macOS

if [ `uname` = Darwin ]; then
  if [[ x`which mrb | grep v1_17_02` != x ]]; then
    unsetup mrb || exit 1
    setup mrb v1_16_02 || exit 1
  fi
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
mrb newDev -v $VERSION -q $QUAL:$BUILDTYPE || exit 1
source localProducts*/setup || exit 1

if [ `uname` = Darwin ]; then
  setup getopt v1_1_6  || exit 1
fi

cd $MRB_SOURCE  || exit 1
maxtries=20
ntries=0
until [ $ntries -ge $maxtries ]
do
  date
  mrb g -r -t $VERSION --repo-type github -g DUNE dunendlar && break
  ntries=$[$ntries+1]
  sleep 60
done
if [ $ntries = $maxtries ]; then
  echo "Could not clone dunendlar using mrb g.  Quitting."
  exit 1
fi


cd $MRB_BUILDDIR || exit 1
mrbsetenv || exit 1
mrb b -j$ncores || exit 1
mrb mp -n dunendlar -- -j$ncores || exit 1

# add dune_pardata to the manifest

manifest=dunendlar-*_MANIFEST.txt

# get platform
OS=$(uname)
case $OS in
    Linux)
        PLATFORM=$(uname -r | grep -o "el[0-9]"|sed s'/el/slf/')
        ;;
    Darwin)
        PLATFORM=$(uname -r | awk -F. '{print "d"$1}')
        ;;
esac

cd $MRB_SOURCE || exit 1

# Extract flavor.

flvr=''
if uname | grep -q Darwin; then
  flvr=`ups flavor -2`
else
  flvr=`ups flavor -4`
fi

# find our set qualifier from artdaq_core's qualifier

SQUAL=`ups active | grep artdaq_core | tr : '\n' | grep ^s | awk '{print $1}'`
echo "Set qualifier from artdaq_core:  $SQUAL"

# Save artifacts.

echo "Moving tarballs to copyBack"

cd $MRB_BUILDDIR || exit 1

mv *.bz2  $WORKSPACE/copyBack/ || exit 1

echo "Moving manifest to copyBack"

manifest=dunendlar-*_MANIFEST.txt
if [ -f $manifest ]; then
  mv $manifest  $WORKSPACE/copyBack/ || exit 1
fi
ls -l $WORKSPACE/copyBack/
cd $WORKSPACE || exit 1
rm -rf $WORKSPACE/temp || exit 1

exit 0

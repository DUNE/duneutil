#!/bin/bash

# build webevd as a DUNE UPS product with mrb
# trj June 7, 2023
# designed to work on Jenkins

echo "Entering script: " $0
cat /etc/os-release

if [[ `grep PRETTY /etc/os-release | grep "Scientific Linux 7"`x = x ]]; then
    echo "Need SL7 -- starting a container with apptainer"
    /cvmfs/oasis.opensciencegrid.org/mis/apptainer/current/bin/apptainer run -B /cvmfs /cvmfs/singularity.opensciencegrid.org/fermilab/fnal-dev-sl7:latest $0
    exit $?
fi
export UPS_OVERRIDE="-H Linux64bit+3.10-2.17"

echo "webevd version: $VERSION"
echo "base qualifiers: $QUAL"
QUAL=`echo ${QUAL} | sed -e "s/-/:/g"`
echo "modified base qualifiers: $QUAL"
echo "build type: $BUILDTYPE"
echo "workspace: $WORKSPACE"


# Get number of cores to use.

ncores=`cat /proc/cpuinfo 2>/dev/null | grep -c -e '^processor'`

if [ $ncores -lt 1 ]; then
  ncores=1
fi
echo "Building using $ncores cores."

# use /grid/fermiapp for macOS builds and cvmfs for Linux

echo "ls /cvmfs/dune.opensciencegrid.org/products/dune/"
ls /cvmfs/dune.opensciencegrid.org/products/dune/
echo

source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh || exit 1

setup git || exit 1
setup gitflow || exit 1

export MRB_PROJECT=dune
echo "MRB path:"
which mrb

rm -rf $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/copyBack || exit 1
rm -f $WORKSPACE/copyBack/* || exit 1
cd $WORKSPACE/temp || exit 1
mrb newDev -v $VERSION -q $QUAL:$BUILDTYPE || exit 1
source localProducts*/setup || exit 1

cd $MRB_SOURCE  || exit 1
maxtries=20
ntries=0
until [ $ntries -ge $maxtries ]
do
  date
  mrb g -r -t $VERSION --repo-type github -g DUNE webevd && break
  ntries=$[$ntries+1]
  sleep 60
done
if [ $ntries = $maxtries ]; then
  echo "Could not clone webevd using mrb g.  Quitting."
  exit 1
fi


cd $MRB_BUILDDIR || exit 1
mrbsetenv || exit 1
mrb b -j$ncores || exit 1
mrb mp -n webevd -- -j$ncores || exit 1

manifest=webevd-*_MANIFEST.txt

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

# Save artifacts.

echo "Moving tarballs to copyBack"

cd $MRB_BUILDDIR || exit 1

mv *.bz2  $WORKSPACE/copyBack/ || exit 1

echo "Moving manifest to copyBack"

manifest=webevd-*_MANIFEST.txt
if [ -f $manifest ]; then
  mv $manifest  $WORKSPACE/copyBack/ || exit 1
fi
ls -l $WORKSPACE/copyBack/
cd $WORKSPACE || exit 1
rm -rf $WORKSPACE/temp || exit 1

exit 0

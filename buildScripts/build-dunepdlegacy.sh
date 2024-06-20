#!/bin/bash

echo "Entering script: " $0
cat /etc/os-release

if [[ `grep PRETTY /etc/os-release | grep "Scientific Linux 7"`x = x ]]; then
    echo "Need SL7 -- starting a container with apptainer"
    /cvmfs/oasis.opensciencegrid.org/mis/apptainer/current/bin/apptainer run -B /cvmfs /cvmfs/singularity.opensciencegrid.org/fermilab/fnal-dev-sl7:latest $0
    exit $?
fi
export UPS_OVERRIDE="-H Linux64bit+3.10-2.17"

#QUAL=`echo ${QUAL} | sed -e "s/-/:/g"`
echo "base qualifiers: $QUAL"
#QUALCOLON=`echo ${QUAL} | sed -e "s/-/:/g"`
QUALCOLON=${QUAL}:${BUILDTYPE}
echo "modified base qualifiers: $QUALCOLON"
echo "build type: $BUILDTYPE"
echo "workspace: $WORKSPACE"
echo "version: $VERSION"

ncores=`cat /proc/cpuinfo 2>/dev/null | grep -c -e '^processor'`
echo "Building using $ncores cores."

if [ -x /cvmfs/grid.cern.ch/util/cvmfs-uptodate ]; then
  /cvmfs/grid.cern.ch/util/cvmfs-uptodate /cvmfs/dune.opensciencegrid.org/products
fi
source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh || exit 1

rm -rf $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/copyBack || exit 1
rm -f $WORKSPACE/copyBack/* || exit 1
cd $WORKSPACE/temp || exit 1

echo "Cloning dunepdlegacy"
mrb newDev -v $VERSION -q $QUAL:$BUILDTYPE || exit 1
source localProducts*/setup || exit 1
cd $MRB_SOURCE  || exit 1
maxtries=20
ntries=0
until [ $ntries -ge $maxtries ]
do
  date
  mrb g -t $VERSION dunepdlegacy && break
  ntries=$[$ntries+1]
  sleep 60
done
if [ $ntries = $maxtries ]; then
  echo "Could not clone dunepdlegacy using mrb g.  Quitting."
  exit 1
fi

cd $MRB_BUILDDIR || exit 1
mrbsetenv || exit 1
mrb b -j$ncores || exit 1
mrb mp -n dunepdlegacy -- -j$ncores || exit 1

mv *bz2 $WORKSPACE/copyBack/ || exit 1

cd $WORKSPACE || exit 1
rm -rf $WORKSPACE/temp || exit 1
exit 0

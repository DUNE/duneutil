#!/bin/bash

#QUAL=`echo ${QUAL} | sed -e "s/-/:/g"`
echo "base qualifiers: $QUAL"
QUALCOLON=`echo ${QUAL} | sed -e "s/-/:/g"`
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


export GIT_HTTP_LOW_SPEED_LIMIT=1000
export GIT_HTTP_LOW_SPEED_TIME=600

rm -rf $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/temp || exit 1
mkdir -p $WORKSPACE/copyBack || exit 1
rm -f $WORKSPACE/copyBack/* || exit 1
cd $WORKSPACE/temp || exit 1

mkdir src || exit 1
cd src || exit 1

echo "Cloning dunepdlegacy"
maxtries=20
ntries=0
until [ $ntries -ge $maxtries ]
do
  date
  git clone git@github.com:DUNE/dunepdlegacy.git && break
  ntries=$[$ntries+1]
  sleep 60
done
if [ $ntries = $maxtries ]; then
  echo "Could not clone $repo using mrb g.  Quitting."
  exit 1
fi

cd dunepdlegacy || exit 1
git checkout tags/$VERSION || exit 1

cd $WORKSPACE/temp || exit 1
mkdir build || exit 1
cd build || exit 1

if [[ "$QUAL" == *"prof" ]]; then
  FLAG="-p"
else
  FLAG="-d"
fi

source $WORKSPACE/temp/src/dunepdlegacy/ups/setup_for_development $FLAG $QUALCOLON || exit 1

buildtool -v -p --generator ninja -j$ncores || exit 1

##build manifest name
dot_version=`echo $VERSION | sed -e "s/_/./g"`
manifest=dunepdlegacy-$dot_version-$SQLITE_FQ-${QUAL}_MANIFEST.txt
echo $manifest

dunepdlegacy_version=`ups active | grep dunepdlegacy | awk '{print $2}'`
echo "dunepdlegacy version: $dunepdlegacy_version"
dunepdlegacy_flavor=`ups active | grep dunepdlegacy | awk '{print $4}'`
echo "dunepdlegacy flavor: $dunepdlegacy_flavor"
dunepdlegacy_quals=`ups active | grep dunepdlegacy | awk '{print $6}'`
echo "dunepdlegacy quals: $dunepdlegacy_quals"
dunepdlegacy_dot_version=`echo ${dunepdlegacy_version} | sed -e 's/_/./g' | sed -e 's/^v//'`
dunepdlegacy_tar=`ls *bz2`
echo "dunepdlegacy          ${dunepdlegacy_version}        ${dunepdlegacy_tar}    -f ${dunepdlegacy_flavor}    -q  ${dunepdlegacy_quals}" >>  $manifest
#echo "dunepdlegacy ${}" >> $manifest

mv $manifest $WORKSPACE/copyBack/ || exit 1
mv $dunepdlegacy_tar $WORKSPACE/copyBack/ || exit 1

cd $WORKSPACE || exit 1
rm -rf $WORKSPACE/temp || exit 1
exit 0

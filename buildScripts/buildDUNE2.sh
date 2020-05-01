#!/bin/bash

# build dunetpc and related packages.
# uses buildFW
# designed to work on Jenkins

# Extract set qualifier from $LARSOFT_QUAL (we don't care about anything else in $LARSOFT_QUAL).

SQUAL=`echo $LARSOFT_QUAL | tr : '\n' | grep ^s`

echo "dunetpc version: $VERSION"
echo "base qualifiers: $QUAL"
echo "set qualifier: $SQUAL"
echo "build type: $BUILDTYPE"
echo "workspace: $WORKSPACE"

# Parse qualifier parameter into base qualifier and label (if any).
# Use hyphen as separator.

basequal=''
label=''
quals=`echo $QUAL | tr '-' ' '`
for q in $quals
do
  if [[ $q == e* || $q == c* ]]; then
    basequal=$q
  else
    label=$q
  fi
done
echo "basequal: $basequal"
echo "label: $label"

if [ x$basequal = x ]; then
  echo "No base qualifier."
  exit 1
fi

# Create area for biuld artifacts.
rm -rf $WORKSPACE/copyBack
mkdir -p $WORKSPACE/copyBack || exit 1

# Check for unsupported combinations of base qualifier, OS, and build label.
if [[ `uname -s` == Darwin ]] && [[ $basequal == e* ]]; then
  echo "${basequal} build not supported on `uname -s`"
  echo "${basequal} build not supported on `uname -s`" > $WORKSPACE/copyBack/skipping_build
  exit 0
fi
if [[ `uname -s` == Darwin ]] && [[ x$label == xpy2 ]]; then
  echo "Python 2 build not supported on `uname -s`"
  echo "Python 2 build not supported on `uname -s`" > $WORKSPACE/copyBack/skipping_build
  exit 0
fi
if [[ `uname -s` == Linux ]] && [[ `lsb_release -rs` == 6* ]] && [[ x$label == x ]] && [[ $basequal != e17 ]] && [[ $basequal != c2 ]]; then
  echo "Python 3 build not supported on SL6"
  echo "Python 3 build not supported on SL6" > $WORKSPACE/copyBack/skipping_build
  exit 0
fi

# Create build directory and go there.
blddir=${WORKSPACE}/build
logdir=${WORKSPACE}/log
rm -rf $blddir
rm -rf $logdir
mkdir -p $blddir || exit 1
mkdir -p $logdir || exit 1
cd $blddir || exit 1

# Fetch buildFW script.
echo "Fetching buildFW."
curl --fail --silent --location --insecure -O http://scisoft.fnal.gov/scisoft/bundles/tools/buildFW || exit 1
chmod +x buildFW

# Do build.
echo
echo "Begin build."
echo
if [ x$label = x ]; then
  ./buildFW -t -b $basequal -s $SQUAL $blddir $BUILDTYPE dune-$VERSION || \
  { mv *.log $logdir
    exit 1
  }
else
  ./buildFW -t -b $basequal -s $SQUAL -l $label $blddir $BUILDTYPE dune-$VERSION || \
  { mv *.log $logdir
    exit 1
  }
fi

# Save log files.

mv *.log $logdir || exit 1

# Save artifacts.

mv dunetpc*.bz2  $WORKSPACE/copyBack/ || exit 1
mv dune_raw_data*.bz2  $WORKSPACE/copyBack/ || exit 1
mv lbne_raw_data*.bz2  $WORKSPACE/copyBack/ || exit 1
mv *.txt $WORKSPACE/copyBack/ || exit 1

# Clean up.

cd $WORKSPACE || exit 1
rm -rf $blddir || exit 1

exit 0

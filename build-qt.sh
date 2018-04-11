#!/bin/sh
#
# Download and build Qt for desktop
#
# Usage:  build-qt.sh [-h] [-n] -[<n>]
# Options:
#
# -h   Help
# -n   No-execute, just show commands
# -<n> Perform build step <n>, where <n> is:
#
# 0 - download
# 1 - extract source
# 2 - configure
# 3 - build
# 4 - install
# 5 - build docs
# 6 - install docs
# 7 - make tar file of build
# 8 - remove source
# 9 - remove install

# Qt version to build
VERSION_MAJOR=5
VERSION_MINOR=10
VERSION_PATCH=1

# Set if needed for a beta or RC version, e.g. "-beta4"
# Leave empty for release.
VERSION_SUFFIX=

# Build type, "full" or "minimal"
#BUILD_TYPE="full"
BUILD_TYPE="minimal"

# Number of parallel jobs to run
PAR=1

# Stop on error
set -e

# Build directory
BUILD_DIR=${HOME}/qtbuild

# Parse command line options
while getopts "hn0123456789" opt; do
  case $opt in
    h)
      echo "usage: $0 [-h] [-n] -[<n>]"
      echo ""
      echo "Options:"
      echo "  -h   Help"
      echo "  -n   No-execute, just show commands"
      echo "  -<n> Perform only build step <n>, where <n> is:"
      echo "        0 - download"
      echo "        1 - extract source"
      echo "        2 - configure"
      echo "        3 - build"
      echo "        4 - install"
      echo "        5 - build docs"
      echo "        6 - install docs"
      echo "        7 - make tar file of build"
      echo "        8 - remove source"
      echo "        9 - remove install"
      exit
      ;;
    n)
      no_exec=1
      ;;
    0)
      step_0=1
      ;;
    1)
      step_1=1
      ;;
    2)
      step_2=1
      ;;
    3)
      step_3=1
      ;;
    4)
      step_4=1
      ;;
    5)
      step_5=1
      ;;
    6)
      step_6=1
      ;;
    7)
      step_7=1
      ;;
    8)
      step_8=1
      ;;
    9)
      step_9=1
      ;;
    \?)
      exit
      ;;
  esac
done

# if no build steps were specified, enable them all.
if [ -z "$step_0$step_1$step_2$step_3$step_4$step_5$step_6$step_7$step_8$step_8" ]
then
    step_0=1
    step_1=1
    step_2=1
    step_3=1
    step_4=1
    step_5=1
    step_6=1
    step_7=1
    step_8=1
    step_9=1
fi

# Generate name of archive file
VER2="${VERSION_MAJOR}.${VERSION_MINOR}"
VER3="${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}"
SOURCE="qt-everywhere-src-${VER3}${VERSION_SUFFIX}.tar.xz"
# Releases prior to Qt 5.10.0 use this format:
#SOURCE="qt-everywhere-opensource-src-${VER3}${VERSION_SUFFIX}.tar.xz"

# Name of source directory
DIR=`basename ${SOURCE} .tar.xz`

# Name of created build archive file
if [ ${BUILD_TYPE} = "full" ]
then
    BUILD="Qt${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}-RaspberryPi3-bin-full.tgz"
elif [ ${BUILD_TYPE} = "minimal" ]
then
    BUILD="Qt${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}-RaspberryPi3-bin-minimal.tgz"
else
    echo "Unknown build type: ${BUILD_TYPE}"
    exit 1
fi

echo "*** Building Qt ${VER3}${VERSION_SUFFIX}"
if [ ! -d "${BUILD_DIR}" ]
then
    if [ -n "$no_exec" ]
    then
        echo mkdir -p "${BUILD_DIR}"
    else
        mkdir -p "${BUILD_DIR}"
    fi
fi

if [ -n "$no_exec" ]
then
    echo cd ${BUILD_DIR}
else
    cd ${BUILD_DIR}
fi

# Download source if needed.
if [ -n "$step_0" ]
then
    if [ -f "${SOURCE}" ]
    then
        echo "*** Source found, not downloading it"
    else
        echo "*** Downloading source"
        if [ -n "$no_exec" ]
        then
            echo wget http://download.qt.io/official_releases/qt/${VER2}/${VER3}/single/${SOURCE}
        else
            wget http://download.qt.io/official_releases/qt/${VER2}/${VER3}/single/${SOURCE}
        fi
    fi
fi

# Check that a build was not already extracted
if [ -d ${DIR} ]
then
  echo "A build already exists in ${DIR}"
  echo "Remove it before doing a build."
  if [ -z "$no_exec" ]
  then
      exit 1
  fi
fi

# Extract source
echo "*** Extracting source"
if [ -n "$no_exec" ]
then
    echo tar xJf ${SOURCE}
    echo cd ${DIR}
else
    tar xJf ${SOURCE}
    cd ${DIR}
fi

# Remove modules that are too big to build natively.
echo "*** Removing qtlocation and qtwebengine"
if [ -n "$no_exec" ]
then
    echo rm -rf qtlocation qtwebengine
else
    rm -rf qtlocation qtwebengine
fi

# Configure
echo "*** Configuring"
if [ ${BUILD_TYPE} = "minimal" ]
then
    if [ -n "$no_exec" ]
    then
        echo ./configure -opensource -confirm-license -nomake examples -nomake tests
    else
        ./configure -opensource -confirm-license -nomake examples -nomake tests
    fi
else
    if [ -n "$no_exec" ]
    then
        echo ./configure -opensource -confirm-license
    else
        ./configure -opensource -confirm-license
    fi
fi

# Build
echo "*** Building"
if [ -n "$no_exec" ]
then
    echo make -s -j${PAR}
else
    make -s -j${PAR}
fi

# Install
echo "*** Installing"
if [ -n "$no_exec" ]
then
    echo sudo make -s install
else
    sudo make -s install
fi

# Build docs
if [ ${BUILD_TYPE} = "full" ]
then
  echo "*** Building docs"
  if [ -n "$no_exec" ]
  then
      echo make -s -j${PAR} docs
  else
      make -s -j${PAR} docs
  fi
fi

# Install docs
if [ ${BUILD_TYPE} = "full" ]
then
  echo "*** Installing docs"
  if [ -n "$no_exec" ]
  then
      echo sudo make -s install_docs
  else
      sudo make -s install_docs
  fi
fi

# Make tar file of build
echo "*** Making tar file of build"
if [ -n "$no_exec" ]
then
    echo cd ..
    echo tar czf ${BUILD} /usr/local/Qt-${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}
else
    cd ..
    tar czf ${BUILD} /usr/local/Qt-${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}
fi

# Remove source
echo "*** Removing source"
if [ -n "$no_exec" ]
then
    echo rm -rf ${DIR}
else
    rm -rf ${DIR}
fi

# Remove install
echo "*** Removing install"
if [ -n "$no_exec" ]
then
    echo sudo rm -rf /usr/local/Qt-${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}
else
    sudo rm -rf /usr/local/Qt-${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}
fi

# Done.
echo "*** Done, build is in ${BUILD}"

#!/bin/bash
# This script is auto-generated by BGP-SRx Software Suite Bundler V2.4.5

# Date: Fri Mar 20 11:48:48 EDT 2020
# CMD: /usr/local/bin/get-BGPSRx -s

SCRIPTNAME='BGP-SRx Software Suite V5.0.5 Build script!'
# Check the parameter $1, if 0 OK if 1 display error $2 and exit

# The prefix directory where everything gets installed in
INSTALL_DIR="$(pwd)/$(dirname $0)"
LOC_PREFIX=$(echo $INSTALL_DIR/local-5.0.5 | sed -e "s/\/\.\//\//g")

DO_CONFIGURE=1
DO_MAKE=1
DO_INSTALL=1
DO_DISTCLEAN=0
DO_UPDATE=0
AUTOMATED=
DO_SCA=0
DO_SRxSnP=0
DO_QSRx=0
DO_BIO=0

CRS_USER=""
CRS_PASSWORD=""
CRS_CMD="svn"

function svn_credentials()
{
  read -p "SVN Username ($(whoami)): " CRS_USER
  if [ "$CRS_USER" == "" ] ; then
    CRS_USER=$(whoami)
  fi
  CRS_CMD="svn --no-auth-cache --username=$CRS_USER"

  read -sp "Password for $CRS_USER: " CRS_PASSWORD
  if [ "$CRS_PASSWORD" != "" ] ; then
    CRS_CMD="$CRS_CMD --password=$CRS_PASSWORD --non-interactive"
  fi
  echo
}

function disclaimer()
{
  local YN=$1
  local COUNT=0
  echo "This script is provided as a helper for building the BGP-SRx Software Suite."
  echo "We thoroughly tested this script but still, you use this script at your own risk."
  while [ "$YN" == "" ] ; do
    read -p "Do you want to continue? [Y/N] " YN
    case $YN in
      [Yy] ) ;;
      [Nn] ) exit ;;
      *)
        COUNT=$(($COUNT + 1))
        YN="" ;;
    esac
    if [ $COUNT -eq 3 ] ; then
      exit;
    fi
  done
}

# Print the syntax and exit
function syntax()
{
  echo
  echo "Syntax: $0 [SCA] [SRxSnP] [QSRx] [BIO] [-C|-M|-I|-D|-U]"
  echo
  echo "  Module selection: If none are specified, build all"
  echo "    SCA:    Build SRx Crypro API"
  echo "    SRxSnP: Build SRx Server and Proxy"
  echo "    QSRx:   Build Quagga SRx"
  echo "    BIO:    Build BGPSEC-IO"
  echo
  echo "  Build MODE: If none is specified, call ./configure ...; make; make install"
  echo "    -A Run the script automated (Disclaimer is answered [Y])"
  echo "    -C Configure only (./configure ...)"
  echo "    -M Compile only   (make)"
  echo "    -I Install only   (make install)"
  echo "    -D Cleanup only   (make uninstall; make distclean)"
  echo
  echo $SCRIPTNAME
  echo "2017/2020 by Oliver Borchert (NIST)"
  exit
}

# check is all needs to be build or just portions
function checkParam()
{
  local DO_ALL=1

  while [ "$1" != "" ] ; do
    case $1 in
      "SCA") DO_SCA=1; DO_ALL=0 ;;
      "SRxSnP") DO_SRxSnP=1; DO_ALL=0 ;;
      "QSRx") DO_QSRx=1; DO_ALL=0 ;;
      "BIO") DO_BIO=1; DO_ALL=0 ;;
      "-A") AUTOMATED="Y" ;;
      "-M")
           # Only "make" and "make install"
           DO_CONFIGURE=0
           DO_MAKE=1
           DO_INSTALL=1
           DO_DISTCLEAN=0
           DO_UPDATE=0
           ;;
      "-C")
           # Only "./configure ..."
           DO_CONFIGURE=1
           DO_MAKE=0
           DO_INSTALL=0
           DO_DISTCLEAN=0
           DO_UPDATE=0
           ;;
      "-I")
           # Only "make install"
           DO_CONFIGURE=0
           DO_MAKE=0
           DO_INSTALL=1
           DO_DISTCLEAN=0
           DO_UPDATE=0
           ;;
      "-D")
           # Only "make distclean"
           DO_CONFIGURE=0
           DO_MAKE=0
           DO_INSTALL=0
           DO_DISTCLEAN=1
           DO_UPDATE=0
           ;;
      "-U")
           # Only "svn update"
           DO_CONFIGURE=0
           DO_MAKE=0
           DO_INSTALL=0
           DO_DISTCLEAN=0
           DO_UPDATE=1
           ;;
      "-?" | "h" | *) syntax ;;
    esac
    shift
  done

  if [ $DO_ALL -eq 1 ] ; then
    DO_SCA=1
    DO_SRxSnP=1
    DO_QSRx=1
    DO_BIO=1
  fi
}

# Check if the configure script exist, if not it generates one.
# If it cannot generate the configure script, it aborts the script with an error
function checkConfig()
{
  # lookup all configure.ac files
  local cfg_ac=($(find | grep configure.ac | sed -e "s/\(.\)configure.ac/\1/g" ))
  for cfg in ${cfg_ac[@]} 
  do 
    if [ ! -e "$cfg"configure ] ; then 
      which autoreconf > /dev/null
      if [ ! $? -eq 0 ] ; then
        echo "ERROR: autoconfig is required to build the configuration script - abort!"
        exit 1
      fi  
      pushd . ; cd $cfg
      autoreconf -i --force
      if [ -e autom4te.cache ] ; then
        rm -rf autom4te.cache
      fi
      popd
    fi 
  done
}

# Exit the shell if    is not 0. In this case  will be used as exit message.
# and    as exit code.
function check()
{
  if [ "$1" != "0" ] ; then
    echo ""
    echo "#######################################################"
    echo "#######################################################"
    echo "  $2"
    echo "#######################################################"
    echo "#######################################################"
    echo ""
    cd ..
    exit 1
  fi
}

# This function does the make and make install
# parameter $1 = Product name
function make_install()
{
  local NAME="$1"
  if [ $DO_MAKE -eq 1 ] ; then
    make -j 2
    check $? "Error building $NAME!"
  fi
  if [ $DO_INSTALL -eq 1 ] ; then
    make install
    check $? "Error installing $NAME!"
  fi
  if [ $DO_DISTCLEAN -eq 1 ] ; then
    make uninstall
    check $? "Error uninstalling $NAME!"
    make distclean
    check $? "Error cleaning $NAME!"
  fi
  if [ $DO_UPDATE -eq 1 ] ; then
    $CRS_CMD update
   check 0 Error updating !
  fi
  cd ..
}

checkParam $@
echo $SCRIPTNAME
disclaimer $AUTOMATED
if [ $DO_UPDATE -eq 1 ] ; then
  svn_credentials
fi

if [ $DO_SCA -eq 1 ] ; then
  # Make and install srx-crypto-api
  DIR=srx-crypto-api
  NAME=SRxCryptoAPI
  echo "Make and install $NAME"...
  cd $DIR
  if [ $DO_CONFIGURE -eq 1 ] ; then
    # Check if a configure script exist, otherwise try to generate one!
    checkConfig
    ./configure --prefix=$LOC_PREFIX CFLAGS="-O0 -g"
    check $? "Error Configuring $NAME!"
  fi
  make_install $NAME
fi

if [ $DO_BIO -eq 1 ] ; then
  # Make and install bgpsec-io
  DIR=bgpsec-io
  NAME=BGPSEC-IO
  echo "Make and install $NAME"...
  cd $DIR
  if [ $DO_CONFIGURE -eq 1 ] ; then
    # Check if a configure script exist, otherwise try to generate one!
    checkConfig
    ./configure --prefix=$LOC_PREFIX sca_dir=$LOC_PREFIX CFLAGS="-O0 -g"
    check $? "Error Configuring $NAME!"
  fi
  make_install $NAME
fi

if [ $DO_SRxSnP -eq 1 ] ; then
  # Make and install srx-server
  DIR=srx-server
  NAME=SRx-Server
  echo "Make and install $NAME"...
  cd $DIR
  if [ $DO_CONFIGURE -eq 1 ] ; then
    # Check if a configure script exist, otherwise try to generate one!
    checkConfig src
    ./configure --prefix=$LOC_PREFIX sca_dir=$LOC_PREFIX CFLAGS="-O0 -g"
    check $? "Error Configuring $NAME!"
  fi
  make_install $NAME
fi

if [ $DO_QSRx -eq 1 ] ; then
  # Make and install quagga-srx
  DIR=quagga-srx
  NAME=QuaggaSRx
  echo "Make and install $NAME"...
  cd $DIR
  if [ $DO_CONFIGURE -eq 1 ] ; then
    # Check if a configure script exist, otherwise try to generate one!
    checkConfig
    ./configure --prefix=$LOC_PREFIX --disable-doc --enable-user=root --enable-group=root --enable-srxcryptoapi sca_dir=$LOC_PREFIX srx_dir=$LOC_PREFIX CFLAGS="-O0 -g"
    check $? "Error Configuring $NAME!"
  fi
  make_install $NAME
fi

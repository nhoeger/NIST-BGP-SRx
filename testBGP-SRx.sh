#!/bin/bash
# This script is auto-generated by BGP-SRx Software Suite Bundler V2.4.5

# Date: Fri Mar 20 11:48:21 EDT 2020
# CMD: /usr/local/bin/get-BGPSRx -s

#!/bin/sh

SCA=$(ls | grep srx-crypto-api)
SRx=$(ls | grep srx-server)
QSRx=$(ls | grep quagga-srx)
BIO=$(ls | grep bgpsec-io)
SCA_DIR=$(pwd)/SCA
SRx_DIR=$(pwd)/$SRx
QSRx_DIR=$(pwd)/$QSRx
BIO_DIR=$(pwd)/$BIO
LOC_DIR=$(pwd)/$(ls | grep local)
if [ ! $? -eq 0 ] ; then
  echo
  echo "Could not find installed binaries, call buildfile [buildBGP-SRx4.1.3.sh] first!"
  echo
  exit 1
fi
BIN_DIR=$LOC_DIR/bin
SBIN_DIR=$LOC_DIR/sbin
ETC_DIR=$LOC_DIR/etc
READ_TAB=""

SCA_TEST=0
BIO_TEST=0
QSRx_TEST=0
GLOBAL_YN=""

echo "SCA_DIR:  $SCA_DIR"
echo "SRx_DIR:  $SRx_DIR"
echo "QSRx_SIR: $QSRx_DIR"
echo "BIO_DIR:  $BIO_DIR"
echo "LOC_DIR:  $LOC_DIR"

function syntax()
{
  echo "Syntax: $0 [-?|?|-h] [-Y|-N]"
  echo
  echo "  Options:"
  echo "    -?, ?, -h  This screen"
  echo "    -Y         No interactive - all questions are Yes"
  echo "    -N         No interactive - all questions are No"
  echo
  echo " 2017/2020 by NIST/ANTD (bgpsrx-dev@nist.gov)"
  exit $1
}

function parseParam()
{
  while [ "$1" != "" ] ; do
    case "$1" in
      "-Y") GLOBAL_YN="Y" ;;
      "-N") GLOBAL_YN="N" ;;
      *) syntax 1
    esac
    shift
  done
}

# Read the keyboard and returns 0 on NO and 1 ON yes
function readYN()
{
  local YN=$GLOBAL_YN
  local TEXT=$READ_TAB"Continue ? [Y/N] "
  if [ "$1" != "" ] ; then
    TEXT="$READ_TAB$1 [Y/N] "
  fi

  while [ "$YN" == "" ] ; do
    read -p "$TEXT" YN
    case $YN in
     "y" | "Y") return 1 ;;
     "n" | "N") return 0 ;;
     *) YN="" ;;
    esac
  done
}

# this function retrieves the systems IPv4 address which should be
# used and writes it into SYS_IP. If more are available, user input
# is requested.
function fill_SYS_IP()
{
  local ip_addr=($(ifconfig | grep -e "inet \(addr:\)\?" | sed -e "s/.*inet [adr:]*\([0-9\.]\+\) .*/\1/g" | sed "/127\.0\.0\.1/d"))
  if [ $? -gt 0 ] ; then
    local ip_addr=($(ip addr show | grep -e "inet \(addr:\)\?" | sed -e "s/.*inet [adr:]*\([0-9\.]\+\)\/[0-9]\+ .*/\1/g" | sed "/127\.0\.0\.1/d"))
  fi
  local addr
  local idx=1
  local selected=0
  if [ ${#ip_addr[@]} -gt 1 ] ; then
    while [ $selected -lt 1 ] || [ $selected -gt ${#ip_addr[@]} ] ; do
      echo "  Select from the following IP Addresses:"
      for addr in "${ip_addr[@]}" ; do
        echo "  - [$idx]: $addr"
        idx=$(($idx + 1))
      done
      read -p "  Select address: " selected
      echo "$selected" | grep -e "^[0-9]\+$" > /dev/null
      if [ ! $? -eq 0 ] ; then
        echo "  Error: Invalid input - select between 1 and ${#ip_addr[@]}"
        selected=0
      fi
      idx=1
    done
    selected=$(($selected -1))
    SYS_IP=${ip_addr[$selected]}
  else
    SYS_IP=${ip_addr[0]};
  fi
}

# Test the basic SCA functionality.
function testSCA()
{
  local SCA_CFG=$LOC_DIR/etc/srxcryptoapi.conf
  local OLD_KEY_VOLT="/var/lib/bgpsec-keys/"
  local NEW_KEY_VOLT=$OLD_KEY_VOLT
  local CREATE_CFG=1

  if [ -e $SCA_CFG ] ; then
    readYN "SCA Configuration file  exists, Overwrite ?"
    CREATE_CFG=$?
  fi

  if [ $CREATE_CFG -eq 1 ] ; then
    cat $SCA_CFG.sample | sed -e "s#$OLD_KEY_VOLT#$NEW_KEY_VOLT#g" > $SCA_CFG
  fi

  SCA_TEST=1

  $SBIN_DIR/srx_crypto_tester

  return $?
}

# Test the basic QSRx functionality.
function testQSRx
{
  if [ ! -e $SBIN_DIR/bgpd ] ; then
    echo "  NOTICE! QuaggaSRx not installed, skip Quagga testing!"
    return 2
  fi
  local QSRx_CFG=$ETC_DIR/bgpd.conf
  local QSRx_CFG_SPL=$QSRx_CFG.sampleSRx
  local QSRx_CFG_TMP=/tmp/bgpd.conf.$RANDOM
  #local MY_IP=$(ifconfig | grep -e "inet \(addr:\)\?" | head -n 1  | sed -e "s/.*inet [adr:]*\([0-9\.]\+\) .*/\1/g")
  if [ "$SYS_IP" == "" ] ; then
    fill_SYS_IP
  fi
  local MY_IP=$SYS_IP;
  local KEY_SKI=$(grep "32-SKI" $BIO_DIR/data/ski-list.txt | sed -e "s/32-SKI://g")
  local OLD_RTR_AS="router bgp 7675"
  local NEW_RTR_AS="router bgp 32"
  local OLD_RTR_EVAL="srx evaluation origin_only"
  local NEW_RTR_EVAL="srx evaluation bgpsec"
  local OLD_RTR_NETWORK=" network 10.0.0.0/9"
  local NEW_RTR_NETWORK="! network 10.0.0.0/9"
  local OLD_RTR_SKI="! srx bgpsec ski 0 1 DEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF"
  local NEW_RTR_SKI=" srx bgpsec ski 0 1 $KEY_SKI"
  local OLD_RTR_KEY="! srx bgpsec active 0"
  local NEW_RTR_KEY=" srx bgpsec active 0"
  local OLD_NBR_ASN=" remote-as 7676"
  local NEW_NBR_ASN=" remote-as 64"
  local OLD_NBR_ADR=" neighbor 10.0.1.1 "
  local NEW_NBR_ADR=" neighbor $MY_IP "
  local OLD_NBR_PASSIVE="! neighbor $MY_IP route-map set-nexthop out"
  local NEW_NBR_PASSIVE=" neighbor $MY_IP passive"

  # Generate QSRx configuration
  cat $QSRx_CFG_SPL \
      | sed -e "s#$OLD_RTR_AS#$NEW_RTR_AS#g" \
      | sed -e "s#$OLD_RTR_EVAL#$NEW_RTR_EVAL#g" \
      | sed -e "s#$OLD_RTR_NETWORK#$NEW_RTR_NETWORK#g" \
      | sed -e "s#$OLD_RTR_SKI#$NEW_RTR_SKI#g" \
      | sed -e "s#$OLD_RTR_KEY#$NEW_RTR_KEY#g" \
      | sed -e "s#$OLD_NBR_ADR#$NEW_NBR_ADR#g" \
      | sed -e "s#$OLD_NBR_ASN#$NEW_NBR_ASN#g" \
      | sed -e "s#$OLD_NBR_PASSIVE#$NEW_NBR_PASSIVE#g" \
      > $QSRx_CFG_TMP
  mv $QSRx_CFG_TMP $QSRx_CFG

  echo "  The quagga-srx and bgpsec-io tests need to be done manually"
  echo "   (1) start srx-server..."
  echo "       $BIN_DIR/srx_server &"
  echo "   (2) start quagga as root..."
  echo "       sudo $SBIN_DIR/bgpd -d -f $QSRx_CFG -i /tmp/bgpd.pid"
  echo "   (3) start bgpsec-io..."
  echo "       $BIN_DIR/bgpsecio -d 0 -f $BIN_DIR/bgpsecio.test.cfg.qsrx"
  echo "   (4) telnet localhost 2605"
  return 0
}

# Run through the given list of tests
# $n   = test function
# $n+1 = test name
function doTest()
{
  local TEST_RUN
  local TEST_NAME
  local TEST_RESULT
  READ_TAB="-"
  while [ "$1" != "" ] || [ "$2" != "" ] ; do
    echo "Testing $2..."
    $1
    TEST_RESULT=$?
    echo -n $READ_TAB"test "
    case $TEST_RESULT in
      0) echo "passed!";;
      2) echo "skiped!";;
      *) echo "failed!"
         echo " * Rerun the test manually and capture the screen output! *";;
    esac
    echo
    shift
    shift
  done
}

parseParam $@

echo "Do install tests..."
#SYS_IP will be set in testQSRx itself.
SYS_IP=""
doTest testSCA $SCA testQSRx $QSRx

#!/bin/bash
# UnrealIRCd Onion Management Script
# Disclaimer: imgay

# Edit these, y'asshole.
TORRC="/etc/tor/torrc"
TORLIB="/var/lib/tor/"
UNREALRC="/home/ircd/Unreal3.2.10.2.patched/unrealircd.conf"
UNREAL="/home/ircd/Unreal3.2.10.2.patched/"

echo "[*] UnrealIRC Onion Manager
[*] -h for help
"

while getopts ":ha:d:u:l" opt; do
  case $opt in
    h)
      echo "[*] -a Add new onion ($0 -a username)
[*] -d Delete users onion ($0 -d username)
[*] -u Show users onion information ($0 -u username)
[*] -l List all users onion information
"
      ;;
    a)
      user_name=$OPTARG
      add=1
      ;;
    d)
      del_name=$OPTARG
      del=1
      ;;
    u)
      get_name=$OPTARG
      get=1
      ;;
    l)
      OPT_DETECT=0
      ;;
    \?)
      echo "[*] Invalid option: $opt"
      ;;
  esac
done

function get_user() {
  while read ports;
  do
    if [[ $ports == *$get_name ]]; then
      if [[ $ports == *6667* ]]; then
        port=$(echo "$ports" | awk '{print $3}' | sed "s/127.0.0.1://")
      fi
      if [[ $ports == *6697* ]]; then
        ssl=$(echo "$ports" | awk '{print $3}' | sed "s/127.0.0.1://")
      fi
    fi
  done < $TORRC;

  echo "[*] Username: $get_name"
  echo "[*] Onion: $(cat $TORLIB$get_name/hostname)"
  echo "[*] Port: $port"
  echo "[*] SSL: $ssl"
  echo ""
}

function del_onion() {
  tor="$TORLIB$del_name/"
  sed -i "/$del_name/d" $TORRC
  sed -i "/START $del_name/,/END $del_name/d" $UNREALRC
  rm -rf "${tor}"

  echo "[*] $del_name has... been... PURGED!"
  echo ""
  /etc/init.d/tor reload # edit to suit your linux distro's shit and shit
  $UNREAL./unreal rehash
  exit
}

function add_onion() {
  port=$[ 9000 + $[ RANDOM % 80000 ]]
  if [[ $(netstat -lnt | awk '$6 == "LISTEN" && $4 ~ ".$port"') == *LISTEN* ]]; then
    $port=$[ 9000 + $[ RANDOM % 80000 ]] # enough redundancy, imo.
  fi

  ssl=$[ 9000 + $[ RANDOM % 80000 ]]
  if [[ $(netstat -lnt | awk '$6 == "LISTEN" && $4 ~ ".$ssl"') == *LISTEN* ]]; then
    $ssl=$[ 9000 + $[ RANDOM % 80000 ]]
  fi

  echo "[*] Adding $user_name to torrc"
  echo "
HiddenServiceDir $TORLIB$user_name/
HiddenServicePort 6667 127.0.0.1:$port # $user_name
HiddenServicePort 6697 127.0.0.1:$ssl # $user_name" >> $TORRC

  echo "[*] Adding $user_name to unrealircd.conf"
  echo "
/* START $user_name LISTEN BLOCKS */
listen  127.0.0.1:$port
{   
    options
    {   
        clientsonly;
    };
};
listen  127.0.0.1:$ssl
{   
    options
    {   
        ssl;
        clientsonly;
    };
};
/* END $user_name LISTEN BLOCKS */" >> $UNREALRC

  echo "[*] Success!
  "
  /etc/init.d/tor reload
  $UNREAL./unreal rehash
  
  sleep 2
  
  if [ ! -f $TORLIB$user_name/hostname ]; then
    echo "[-] Failed to generate onion! Check your configuration."
    exit
  fi
  
  echo "[*] Username: $user_name"
  echo "[*] Onion: $(cat $TORLIB$user_name/hostname)"
  echo "[*] Port: $port"
  echo "[*] SSL Port: $ssl"
  
  exit
}

if [ "$(id -u)" != "0" ]; then
   echo "[-] Run as root, rube." 1>&2
   exit 1
fi

if [ "$add" == 1 ]; then
  if [ ! -f $TORLIB$user_name/hostname ]; then
    add_onion
  else
    echo "[-] User already exists!"
    exit 1
  fi
fi

if [ "$del" == 1 ]; then
  if [ ! -f $TORLIB$del_name/hostname ]; then
    echo "[-] User not found!"
    exit 1
  else
    del_onion
  fi
fi

if [ "$get" == 1 ]; then
  if [ ! -f $TORLIB$get_name/hostname ]; then
    echo "[-] User not found!"
    exit 1
  else
    get_user
  fi
fi

if [ "$OPT_DETECT" == 0 ]; then
  echo "[*] Gathering all user informaton ..."
  while read line;
  do
    if [[ $line == *START* ]]; then
      get_name=$(echo "$line" | awk '{print $3}')
      get_user
    fi
  done < "$UNREALRC";
  exit
fi

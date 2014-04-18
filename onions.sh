#!/bin/bash
# UnrealIRCd Onion Management Script
# Disclaimer: imgay

# Edit these, y'asshole.
TORRC="/etc/tor/torrc"
TORLIB="/var/lib/tor/"
UNREALRC="/home/ircd/Unreal3.2.10.2.patched/unrealircd.conf"

echo "[*] UnrealIRC Onion Manager
[*] -h for help
"

while getopts ":ha:d:u:r:e:c:l" opt; do
  case $opt in
    h)
      echo "Usage:
   -a 	Add new onion ($0 -a <username>)
   -d 	Delete users onion ($0 -d <username>)
   -u 	Show users onion information ($0 -u <username>)
   -r 	Respawn users onion ($0 -r <username>)
   -e 	Edit users onion/private_key ($0 -e <username>)
   -c 	Add user with custom onion via shallot ($0 -c <username> <shallot regex>)
   -l 	List all users onion information
"
      ;;
    a)
      user_name=$OPTARG
      ;;
    d)
      del_name=$OPTARG
      ;;
    u)
      get_name=$OPTARG
      ;;
    r)
      del_name=$OPTARG
      redo=1
      ;;
    e)
      edit_name=$OPTARG
      ;;
    c)
      user_name=$2
      regex=$3
      shallot=1
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
  echo "[*] SSL: $ssl
  "
}

function del_onion() {
  tor="$TORLIB$del_name/"
  sed -i "/$del_name/d" $TORRC
  sed -i "/START $del_name/,/END $del_name/d" $UNREALRC
  rm -rf "${tor}"

  echo "[*] $del_name has... been... PURGED!
  "
  killall -HUP tor
  killall -HUP ircd

  if [ "$redo" == 1 ]; then
    user_name=$del_name
    add_onion
  fi
}

function add_onion() {
  port=$[ 9000 + $[ RANDOM % 56535 ]]
  if [[ $(netstat -lnt | awk '$6 == "LISTEN" && $4 ~ ".$port"') == *LISTEN* ]]; then
    $port=$[ 9000 + $[ RANDOM % 56535 ]] # enough redundancy, imo.
  fi

  ssl=$[ 9000 + $[ RANDOM % 56535 ]]
  if [[ $(netstat -lnt | awk '$6 == "LISTEN" && $4 ~ ".$ssl"') == *LISTEN* ]]; then
    $ssl=$[ 9000 + $[ RANDOM % 56535 ]]
  fi

  echo "[*] Adding $user_name to torrc"
  echo "
HiddenServiceDir $TORLIB$user_name/
HiddenServicePort 6667 127.0.0.1:$port # $user_name
HiddenServicePort 6697 127.0.0.1:$ssl # $user_name" >> $TORRC

  if [ "$shallot" == 1 ]; then
    echo "[*] Using shallot to generate custom onion..."
    if [ "$regex" == "" ]; then
      echo "[-] No shallot regex supplied, jerk"
      sed -i "/$user_name/d" $TORRC
      exit 1
    else if command -v shallot 2>/dev/null; then
      killall -HUP tor

      sleep 3

      privkey=$TORLIB$user_name/private_key
      hostname=$TORLIB$user_name/hostname

      shallot -f private_key $regex
      pid=$(ps aux | grep shallot | grep -v "grep" | awk '{print $2}')
      while ps -p $pid > /dev/null 2>&1; do sleep 1; done;

      while read lines;
      do
        if [[ $lines == Found* ]]; then
          echo "$lines" | awk '{print $7}' > $hostname
        fi
      done < private_key;

      sed -i '1,3d' private_key
      cat private_key > $privkey
      rm private_key
    else
      echo "[-] Please install shallot or put it in \$PATH"
      sed -i "/$user_name/d" $TORRC
      exit 1
      fi
    fi
  fi

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

  echo "[*] Reloading Tor/Unreal configs..."
  killall -HUP tor
  killall -HUP ircd
  
  sleep 2

  if [ ! -f $TORLIB$user_name/hostname ]; then
    echo "[-] Failed to generate onion! Check your configuration."
    sed -i "/$user_name/d" $TORRC
    sed -i "/START $user_name/,/END $user_name/d" $UNREALRC
    exit 1
  else
    echo "[*] Success!
  "
  fi

  echo "[*] Username: $user_name"
  echo "[*] Onion: $(cat $TORLIB$user_name/hostname)"
  echo "[*] Port: $port"
  echo "[*] SSL Port: $ssl
  "
}

if [ "$(id -u)" != "0" ]; then
   echo "[-] Run as root, rube." 1>&2
   exit 1
fi

if [ "$user_name" != "" ]; then
  if [ ! -f $TORLIB$user_name/hostname ]; then
    add_onion
  else
    echo "[-] User already exists!"
    exit 1
  fi
fi

if [ "$del_name" != "" ]; then
  if [ ! -f $TORLIB$del_name/hostname ]; then
    echo "[-] User not found!"
    exit 1
  else
    del_onion
  fi
fi

if [ "$get_name" != "" ]; then
  if [ ! -f $TORLIB$get_name/hostname ]; then
    echo "[-] User not found!"
    exit 1
  else
    get_user
  fi
fi

if [ "$edit_name" != "" ]; then
  if [ ! -f $TORLIB$edit_name/hostname ]; then
    echo "[-] User not found!"
    exit 1
  else
    hostname=$TORLIB$edit_name/hostname
    vi $TORLIB$edit_name/private_key
    rm -f {$hostname}
    killall -HUP tor
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
fi

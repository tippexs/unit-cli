#!/usr/bin/env bash

UNITCTRLSOCK=/usr/local/var/run/unit/control.sock
UNITCTRLURL="http://localhost"
COMMAND=${0##*/}
APP_PATH="/home/tippexs/apps"

preflightCheck() {
hash jq 2> /dev/null
  if [ $? -ne 0 ]; then
    echo "$COMMAND: ERROR: 'jq' must be installed"
    jq
   exit 1
  fi
}

helpscreen() {
## Todo: Display Modules from Mac "/usr/local/lib/unit/modules/" and Linux System
	echo "USAGE: $COMMAND [options]"
	echo ""
	echo " NGINX Unit CLI"
	echo " Options:"
    echo " -s | --socket                       # Set Unit Control Socket Path"
	echo " -c | --config      		           # Get the current UNIT configuration "
	echo " -C | --raw-config <ObjectPath JSON> # Apply RAW JSON config"
	echo " -a | --apply <config.json>          # Send a configuration to Unit"
	echo " -i | --init                         # Create an inital configuration"
	echo ""
	exit 1

}


getCurrConfig() {
  curl -s --unix-socket $UNITCTRLSOCK $UNITCTRLURL/config | jq
}

applyConfig() {
  curl --unix-socket $UNITCTRLSOCK --data-binary @$1 $UNITCTRLURL/config
}


# PHP Only fow now. Will be enhanced soon!
createAppStack(){
  APP_CONFIG=$(jo -p type=php targets=$(jo core=$(jo root=$3)) options={} processes=4)
  LST_NAME="*:$2"
  LST_CONFIG=$(jo -p pass=applications/$1)
  curl -X PUT --unix-socket $UNITCTRLSOCK --data "$APP_CONFIG" $UNITCTRLURL/config/applications/$1
  curl -X PUT --unix-socket $UNITCTRLSOCK --data "$LST_CONFIG" $UNITCTRLURL/config/listeners/$LST_NAME
}


initConfiguration() {
  INITCONFIG=$(jq -n '{
  "settings": {"http": {"header_read_timeout": 10}},
  "listeners": {},
  "upstreams": {},
  "routes": {},
  "applications": {},
  "access_log": "/var/log/unit.access.log"
  '})

   curl -X PUT --unix-socket $UNITCTRLSOCK --data "$INITCONFIG" $UNITCTRLURL/config
}

applyRawConfig() {
   curl -X PUT --unix-socket $UNITCTRLSOCK --data $2 $UNITCTRLURL/config/$1
}


# ###### MAIN Program

preflightCheck

if [ $# -lt 1 ]; then
  helpscreen
fi

while [ $# -ge 1 ]; do
  case "$1" in
    "-c" | "--config")
      getCurrConfig
      shift
    ;;

	"-C" | "--raw-config")
	  applyRawConfig $2 $3
	  shift; shift; shift
	;;

	"-A" | "--create-app")
	createAppStack $2 $3 $4
	shift; shift; shift; shift
	;;

    "-a" | "--apply")
      applyConfig $2
      shift; shift
    ;;

	"-i" | "--init")
	  initConfiguration
	  shift
	;;
  esac
done
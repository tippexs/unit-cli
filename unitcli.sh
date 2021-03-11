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
	echo " 💚 NGINX Unit CLI 💚"
	echo " Options:"
  echo " -s | --socket                         # Set Unit Control Socket Path"
	echo " -c | --config                         # Get the current UNIT configuration "
	echo " -C | --raw-config <ObjectPath JSON>   # Apply RAW JSON config"
	echo " -a | --apply <config.json> [--debug]  # Send a configuration to Unit (AppSpec Format)"
	echo " -i | --init                           # ✨ Create an inital configuration"
	echo ""
	exit 1

}


getCurrConfig() {
  curl -s --unix-socket $UNITCTRLSOCK $UNITCTRLURL/config | jq
}

applyConfig() {
  echo "🧙 UNIT Configuration Wizzard "
  CONFIGFILE_PATH=$1
  DEBUG_OUTPUT=$2
  # APPLY Target Configuraiton frist (Applications / Upstreams)
  echo "✨ Applying UNIT AppSpec Applications / Upstreams Configuration"

  for a in $(jq '.applications | keys | .[]' $1); do
    APP_CFG=$(jq -r ".applications[$a]" $1)
    APP_NAME=$(echo $a |sed -e 's/"//g')
    echo "💫 🛠 Applying Application Configuration for $APP_NAME"
    APP_CFG=$(jq -r ".applications[$a]" $1)
    if [ $DEBUG_OUTPUT ]; then echo -n $APP_CFG |jq; fi
    curl --unix-socket $UNITCTRLSOCK -X PUT --data "$APP_CFG" $UNITCTRLURL/config/applications/$APP_NAME

  done

  {
   for u in $(jq '.upstreams | keys | .[]' $1 2>/dev/null ); do
    {
    UPS_CFG=$(jq -r ".upstreams[$u]" $1)
    UPS_NAME=$(echo $u |sed -e 's/"//g')
    echo "✨ Create Upstream for $UPS_NAME"
    if [ $DEBUG_OUTPUT ]; then echo -n $UPS_CFG|jq; fi
    curl --unix-socket $UNITCTRLSOCK -X PUT --data "$UPS_CFG" $UNITCTRLURL/config/upstreams/$UPS_NAME
    } || {echo -n "Error while applying Upstream configuration...."}
  done
  } || {}
  
  # APPLY Routes Configuraiton next
  echo "✨ Applying UNIT AppSpec Network Configuration - Linking..."
  {
  for r in $(jq '.routes | keys | .[]' $1  2>/dev/null ); do
  {
   ROUTE_CFG=$(jq -r ".routes[$r]" $1)
   ROUTE_NAME=$(echo $r |sed -e 's/"//g')
   echo "💫 🚦 Applying Route Configuration for $ROUTE_NAME"

   ROUTE_CFG=$(jq -r ".routes[$r]" $1)
   if [ $DEBUG_OUTPUT ]; then echo -n $ROUTE_CFG |jq; fi
   curl --unix-socket $UNITCTRLSOCK -X PUT --data "$ROUTE_CFG" $UNITCTRLURL/config/routes/$ROUTE_NAME
  } || {echo -n "error applying Route configuration..."}
  done
  }
  
  for k in $(jq '.listeners | keys | .[]' $CONFIGFILE_PATH); do
    LIST_CFG=$(jq -r ".listeners[$k]" $CONFIGFILE_PATH)
    LIST_NAME=$(echo $k |sed -e 's/"//g')
    echo "✨ Create Listener for $LIST_NAME"
    if [ $DEBUG_OUTPUT ]; then echo -n $LIST_CFG |jq; fi
    curl --unix-socket $UNITCTRLSOCK -X PUT --data "$LIST_CFG" $UNITCTRLURL/config/listeners/$LIST_NAME
  done

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
      if [[ "$#" -eq 3 && "$3" != "--debug" ]]; then
        echo "🚨 Unknown flag $3"
        exit 1;
      fi
      applyConfig $2 $3
      shift; shift; shift
    ;;

	"-i" | "--init")
	  initConfiguration
	  shift
	;;
  esac
done
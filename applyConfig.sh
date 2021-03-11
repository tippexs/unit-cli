#!/usr/bin/env bash
echo "🧙 UNIT Configuration Wizzard "

# for k in $(jq '.listeners | keys | .[]' $1); do
#    echo $k
#    LIST_CFG=$(jq -r ".listeners[$k]" $1)
#    LIST_NAME=$(echo $k |sed -e 's/"//g')
#    echo $(jq -r ".listeners[$k]" $1)
#    echo $LIST_NAME
#    curl --unix-socket /var/run/unit/control.sock -X PUT --data "$LIST_CFG" http://localhost/config/listeners/$LIST_NAME
# done

# for u in $(jq '.upstreams | keys | .[]' $1); do
#    echo $u
#    UPS_CFG=$(jq -r ".upstreams[$u]" $1)
#    UPS_NAME=$(echo $u |sed -e 's/"//g')
#    echo $UPS_CFG
#    curl --unix-socket /var/run/unit/control.sock -X PUT --data "$UPS_CFG" http://localhost/config/upstreams/$UPS_NAME
# done

for r in $(jq '.routes | keys | .[]' $1); do
   ROUTE_CFG=$(jq -r ".routes[$r]" $1)
   ROUTE_NAME=$(echo $r |sed -e 's/"//g')
   echo "💫 🚦 Applying Route Configuration for $ROUTE_NAME"

   ROUTE_CFG=$(jq -r ".routes[$r]" $1)
   echo -n $ROUTE_CFG |jq
  
done

for a in $(jq '.applications | keys | .[]' $1); do
   APP_CFG=$(jq -r ".applications[$a]" $1)
   APP_NAME=$(echo $a |sed -e 's/"//g')
   echo "💫 🛠 Applying Application Configuration for $APP_NAME"

   APP_CFG=$(jq -r ".applications[$a]" $1)
   echo -n $APP_CFG |jq

done
#!/opt/bin/sh
WAN_IP=`nvram show | grep 'wan_ipaddr=\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}'`
WANIP=`echo ${WAN_IP/wan_ipaddr=/}`
echo "Connecting 3322.org, setting ddns to: $WANIP"

UID='$USERNAME$'
PWD='$PASSWORD$'
HOSTNAME='$USER_DOMAIN$.3322.org'

wget -q -O ipupdate "http://$UID:$PWD@members.3322.org/dyndns/update?&hostname=$HOSTNAME&myip=$WANIP"
ret=`awk '{if($1~/good/ || $1~/nochg/) print $1}' ipupdate|sed -n '1p'`
if [ "$ret"="good" -o "$ret"="nochg" ]; then
  echo "update internet ip $ret: $WANIP"
  logger "update internet ip $ret: $WANIP"
else
  echo "update internet ip failure!"
  logger "update internet ip failure!"
fi

#!/usr/bin/env sh
# set -eu

if [ ! -e /dev/net/tun ]; then
  echo 'FATAL: cannot start ZeroTier One in container: /dev/net/tun not present.'
  exit 1
fi

echo "Starting..."
#zerotier-one
supervisord -c /etc/supervisor/supervisord.conf

sleep 10
echo "joining..."
zerotier-cli join $NETWORK_ID

IP_OK=0
while [ $IP_OK -lt 1 ]
do
  ZTDEV=$( ip addr | grep -i zt | grep -i mtu | awk '{ print $2 }' | cut -f1 -d':' | tail -1 )
  IP_OK=$( ip addr show dev $ZTDEV | grep -i inet | wc -l )
  sleep 10

  echo $IP_OK

  echo "Auto accept the new client"
  HOST_ID="$(zerotier-cli info | awk '{print $3}')"

  curl -s -XPOST \
    -H "Authorization: Bearer $ZTAUTHTOKEN" \
    -d '{"hidden":"false","config":{"authorized":true}}' \
    "https://$ZT_MOON/network/$NETWORK_ID/member/$HOST_ID"

  echo "Set hostname"

  curl -s -XPOST \
    -H "Authorization: Bearer $ZTAUTHTOKEN" \
    -d "{\"name\":\"$ZTHOSTNAME\"}" \
    "https://$ZT_MOON/network/$NETWORK_ID/member/$HOST_ID"

  echo "\nDone \n"
done

tail -f /dev/null
#!/usr/bin/env sh
zerotier-cli join $NETWORK_ID

echo "Auto accept the new client"
HOST_ID="$(zerotier-cli info | awk '{print $3}')"

curl -s -XPOST \
  -H "x-zt1-auth: $ZTAUTHTOKEN" \
  -d "{\"name\":\"$ZTHOSTNAME\", \"ipAssignments\":[\"$ZT_NODE_IP\"], \"authorized\":true}" \
  "http://$ZT_MOON/controller/network/$NETWORK_ID/member/$HOST_ID"

echo "\nDone \n"
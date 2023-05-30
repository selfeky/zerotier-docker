#!/usr/bin/env sh
# set -eu

echo "Stopping..."
 
HOST_ID="$(zerotier-cli info | awk '{print $3}')"

curl -s -XPOST \
  -H "x-zt1-auth: $ZTAUTHTOKEN" \
  -d "{\"name\":\"$ZTHOSTNAME\", \"ipAssignments\":[\"\"], \"authorized\":false}" \
  "http://$ZT_MOON/controller/network/$NETWORK_ID/member/$HOST_ID"

echo "\nDone \n"
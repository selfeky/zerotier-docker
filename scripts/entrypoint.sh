#!/usr/bin/env sh
set -Eeo pipefail

if [ "${1:0:1}" = '-' ]; then
	set -- zerotier-one "$@"
fi

DEFAULT_PRIMARY_PORT=9993
DEFAULT_PORT_MAPPING_ENABLED=true
DEFAULT_ALLOW_TCP_FALLBACK_RELAY=true

MANAGEMENT_NETWORKS=""
if [ ! -z "$ZT_ALLOW_MANAGEMENT_FROM" ]; then
  for NETWORK in ${ZT_ALLOW_MANAGEMENT_FROM//,/$IFS}; do
    if [ -n "$MANAGEMENT_NETWORKS" ]; then
      MANAGEMENT_NETWORKS="${MANAGEMENT_NETWORKS},"
    fi
    MANAGEMENT_NETWORKS="${MANAGEMENT_NETWORKS}\"${NETWORK}\""
  done
fi

if [ "$ZT_OVERRIDE_LOCAL_CONF" = 'true' ] || [ ! -f "/var/lib/zerotier-one/local.conf" ]; then
  echo "{
    \"settings\": {
        \"primaryPort\": ${ZT_PRIMARY_PORT:-$DEFAULT_PRIMARY_PORT},
        \"portMappingEnabled\": ${ZT_PORT_MAPPING_ENABLED:-$DEFAULT_PORT_MAPPING_ENABLED},
        \"softwareUpdate\": \"disable\",
        \"allowManagementFrom\": [${MANAGEMENT_NETWORKS}],
        \"allowTcpFallbackRelay\": ${ZT_ALLOW_TCP_FALLBACK_RELAY:-$DEFAULT_ALLOW_TCP_FALLBACK_RELAY}
    }
  }" > /var/lib/zerotier-one/local.conf
fi

exec "$@"

zerotier-cli join $NETWORK_ID

echo "Auto accept the new client"
HOST_ID="$(zerotier-cli info | awk '{print $3}')"

# curl -s -XPOST \
#   -H "Authorization: Bearer $ZTAUTHTOKEN" \
#   -d '{"hidden":"false","config":{"authorized":true}}' \
#   "https://$ZT_MOON/network/$NETWORK_ID/member/$HOST_ID"

echo "Set hostname"

curl -s -XPOST \
  -H "x-zt1-auth: $ZTAUTHTOKEN" \
  -d "{\"name\":\"$ZTHOSTNAME\", \"ipAssignments\":[\"$ZT_NODE_IP\"], \"authorized\":true}" \
  "https://$ZT_MOON/controller/network/$NETWORK_ID/member/$HOST_ID"

echo "\nDone \n"

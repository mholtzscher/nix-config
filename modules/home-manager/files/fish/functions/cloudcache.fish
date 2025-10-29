set API_TOKEN (op item get cloudflare.com --fields cli-api-token --reveal)
set ZONE_ID (op item get cloudflare.com --fields zone-holtzscher-com)
set URL https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache
set EMAIL (op item get cloudflare.com --fields username)

echo "Purging Cloudflare cache for ZONE_ID: $ZONE_ID"
curl $URL -H "Content-Type: application/json" -H "X-Auth-Email: $EMAIL" -H "Authorization: Bearer $API_TOKEN" -d '{"purge_everything": true}'

#!/bin/bash

# Created by Anthony Darlow (CantScript), June 13, 2025
# Script provided AS IS and without warranty of any kind


########User Variables########

## Client ID from ABM/ASM
client_id="CLIENT ID COPIED FROM AXM"

## Change between ASM and ABM as required
scope="school.api"
#scope="business.api"


###############Do Not Edit Below This Line##############

###Discover Locations
# Get the directory where the script is located
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define the path to the Client Assertion file relative to the script's directory
assertLocation="$scriptDir/../Tokens/client_assertion_format.txt"

# Define the path to the Access Token file relative to the script's directory
aTokenLocation="$scriptDir/../Tokens/access_token_format.txt"

########Functions#########

checkAssertionValidity() {
	local file="${assertLocation}"
	
	if [[ -f "$file" ]]; then
		client_assert=$(awk -F': ' '/^Token:/ {print $2}' "$file")
	else
		echo "Error: $file not found!" >&2
		return 1
	fi
	
	# Extract the human-readable expire date string
	expire_str=$(awk -F': ' '/^Expire:/ {print $2}' "$file")
	
	# Convert expire_str to a Unix timestamp (macOS format)
	expire_ts=$(date -jf "%a %b %d %T %Z %Y" "$expire_str" +%s)
	
	# Get the current time as a Unix timestamp
	now_ts=$(date +%s)
	
	# Compare
	if [[ "$now_ts" -lt "$expire_ts" ]]; then
		echo "Assertion Token is still valid."
		return 0
	else
		echo "Assertion Token has expired."
		return 1
	fi
}

createAccessToken() {
	request_json=$(curl -s -X POST \
-H 'Host: account.apple.com' \
-H 'Content-Type: application/x-www-form-urlencoded' \
"https://account.apple.com/auth/oauth2/token?grant_type=client_credentials&client_id=${client_id}&client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer&client_assertion=${client_assert}&scope=${scope}")
	
	accessToken=$(echo $request_json | jq -r '.access_token')
	
	iat=$(date -u +%s)
	exp=$((iat + 3600)) ## Access token is valid for 1 hour
	
	tee "${aTokenLocation}" > /dev/null <<EOF
AccessToken: $accessToken
Expire: $(date -r $exp)
EOF
	
	echo "Access Token Created"
	
}


###################################################################



if [[ -f "${aTokenLocation}" ]]; then
	accessToken=$(awk -F': ' '/^AccessToken:/ {print $2}' "${aTokenLocation}")
else
	echo "Error: access_token_format.txt not found!" >&2
	echo "Creating Access Token"
	checkAssertionValidity
	createAccessToken 
	sleep 2
	if [[ -f "${aTokenLocation}" ]]; then
		accessToken=$(awk -F': ' '/^AccessToken:/ {print $2}' "${aTokenLocation}")
	else
		echo "Something went wrong"
		exit 1
	fi
fi


#Get expiry from current Access Token
# Extract the human-readable expire date string
expire_str=$(awk -F': ' '/^Expire:/ {print $2}' "${aTokenLocation}")

# Convert expire_str to a Unix timestamp
expire_ts=$(date -jf "%a %b %d %T %Z %Y" "$expire_str" +%s)

# Get the current time as a Unix timestamp
now_ts=$(date +%s)


# Compare
if [[ "$now_ts" -lt "$expire_ts" ]]; then
	echo "Access Token is valid."
else
	echo "Access Token has expired."
	echo "Generating new Access Token...."
	checkAssertionValidity
	createAccessToken 
	sleep 5
	expire_str=$(awk -F': ' '/^Expire:/ {print $2}' "${aTokenLocation}")
	expire_ts=$(date -jf "%a %b %d %T %Z %Y" "$expire_str" +%s)
	echo "New Access Token Expires: $expire_str"
	if [[ "$now_ts" -lt "$expire_ts" ]]; then
		echo "Access Token is now valid."
		echo "Continuing with API Call(s)"
	else
		echo "Something went wrong"
		exit 1
	fi
fi





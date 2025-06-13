#!/bin/zsh

# zsh version of Implementing OAuth for the Apple School and Business Manager API
#   https://developer.apple.com/documentation/apple-school-and-business-manager-api/implementing-oauth-for-the-apple-school-and-business-manager-api
#
# Created by Bart Reardon, June 11, 2025
# Arugmented by Anthony Darlow (CantScript), June 13, 2025
# Script provided AS IS and without warranty of any kind

# Requirements:
#   Private key downloaded from Apple Business Manager or Apple School Manager
#   Client ID - Found in the "Manage" info pane for the API key in ABM/ASM
#   Key ID    - Found in the "Manage" info pane for the API key in ABM/ASM

# The JWT generated is valid for 180 days and does not need to be re-generated every time you want to use it
# Create the JWT once, then use that when requesting a bearer token from the ABM/ASM API.
# re-create once it has expired.

########User Variables########

private_key_file="<NAME OF PEM FROM AXM>"
client_id="<CLIENT ID COPIED FROM AXM>"
team_id="$client_id"
key_id="<KEY ID COPIED FROM AXM>"


###############Do Not Edit Below This Line##############

audience="https://account.apple.com/auth/oauth2/v2/token"
alg="ES256"

iat=$(date -u +%s)
exp=$((iat + 86400 * 180))
jti=$(uuidgen)


###Discover Locations
# Get the directory where the script is located
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define the path to the file relative to the script's directory
pKeyLocation="$scriptDir/../AxmCert/${private_key_file}"

# Check to see if we have all our stuff
if [[ ! -e "$pKeyLocation" ]]; then
  echo "Private key $private_key_file can't be found"
  exit 1
fi
if [[ -z $client_id ]] || [[ -z $key_id ]]; then
  echo "Client ID or Key ID are missing"
  echo "Client ID: $client_id"
  echo " Key ID: $key_id"
  exit 1
fi


# base64url encode
b64url() {
  # Encode base64 to url safe format
  echo -n "$1" | openssl base64 -e -A | tr '+/' '-_' | tr -d '='
}

pad64() {
  # Pad ECDSA signature on the left with 0s until it is exactly 64 characters long (i.e., 32 bytes = 64 hex digits)
  local hex=$1
  printf "%064s" "$hex" | tr ' ' 0
}

# JWT sections
header=$(jq -nc --arg alg "$alg" --arg kid "$key_id" '{alg: $alg, kid: $kid, typ: "JWT"}')
payload=$(jq -nc \
  --arg sub "$client_id" \
  --arg aud "$audience" \
  --argjson iat "$iat" \
  --argjson exp "$exp" \
  --arg jti "$jti" \
  --arg iss "$team_id" \
  '{sub: $sub, aud: $aud, iat: $iat, exp: $exp, jti: $jti, iss: $iss}')

header_b64=$(b64url "$header")
payload_b64=$(b64url "$payload")
signing_input="${header_b64}.${payload_b64}"

# Create temporary file
sigfile=$(mktemp /tmp/sig.der.XXXXXX)

# Sign using EC private key, output raw DER binary to file
echo -n "$signing_input" | openssl dgst -sha256 -sign ${pKeyLocation} > "$sigfile"

# Extract R and S integers using ASN1 parse
r_hex=""
s_hex=""
i=0

while read -r line; do
  hex=$(echo "$line" | awk -F: '/INTEGER/ {print $NF}')
  if [[ -n "$hex" ]]; then
    if [[ $i -eq 0 ]]; then
      r_hex="$hex"
    elif [[ $i -eq 1 ]]; then
      s_hex="$hex"
    fi
    ((i++))
  fi
done < <(openssl asn1parse -in "$sigfile" -inform DER 2>/dev/null)

# Clean up the sig file as we no longer need it
rm $sigfile

# create R and S values
r=$(pad64 "$r_hex")
s=$(pad64 "$s_hex")

# Convert signature to base64  
rs_b64url=$(echo "$r$s" | xxd -r -p | openssl base64 -A | tr '+/' '-_' | tr -d '=')

# form the completed JWT
jwt="${signing_input}.${rs_b64url}"

# Write to file using tee and heredoc
tee $scriptDir/../Tokens/client_assertion_format.txt > /dev/null <<EOF
Token: $jwt
Expire: $(date -r $exp)
EOF



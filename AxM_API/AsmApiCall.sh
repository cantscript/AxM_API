#!/bin/bash

# Created by Anthony Darlow (CantScript), June 13, 2025
# Script provided AS IS and without warranty of any kind


##Required code in all API scripts, will automate validation of Access Token
##or generate a new one if expired

./AutomationScripts/create_access_token.sh
accessToken=$(awk -F': ' '/^AccessToken:/ {print $2}' ./Tokens/access_token_format.txt)

### Code API call and logic below ###

curl "https://api-school.apple.com/v1/mdmServers" -H "Authorization: Bearer ${accessToken}"

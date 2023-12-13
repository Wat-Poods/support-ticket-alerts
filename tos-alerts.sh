#!/bin/bash

# This is a script designed to use ntfy to alert when a ToS Violation ticket is opened on a Linode account. It's designed to run as a cron once an hour, using the Linode API to check tickets opened in the past hour. If a ticket was opened, then it checks the subject line for the string "ToS Violation". If it sees one, it will set an alert through ntfy to let anyone with ntfy settings configured to be alerted.
# For requirements, refer to the README file. 

# This checks if there's a Linode API token found. If there is not one, the script will prtint the message below and then stop. 
# NOTE: This is not checking the permissions of the user the API token was created. If the user does not have permissions, then you will see different output.

if [ ! -f "./LINODE_TOKEN" ]; then
  echo "Error: LINODE_TOKEN file not found. Create a file named 
'LINODE_TOKEN' and only paste the Linode API token."
  exit 1
fi

LINODE_TOKEN=$(cat "LINODE_TOKEN")

# Calculate the timestamp for one hour ago in the format "YYYY-MM-DDTHH:mm:ss"
# For Linux:
# one_hour_ago=$(date -u -d '1 hour ago' +"%Y-%m-%dT%H:%M:%S")
# For MacOS:

one_hour_ago=$(date -v -1H +"%Y-%m-%dT%H:%M:%S")

# Make the API call and capture the response

api_response=$(curl -s -H "Authorization: Bearer $LINODE_TOKEN" "https://api.linode.com/v4/support/tickets" -H "X-Filter: { \"opened\": { \"+gte\": \"$one_hour_ago\" } }")

# Extract and print the summary field
summary=$(echo "$api_response" | jq -r '.data[0].summary')
echo "Summary: $summary"

# Check if the summary includes the specific text

if [[ "$summary" == *"ToS Violation"* ]]; then
  curl -d "You got a new ToS ticket that needs to be reviewed." http://172-233-186-32.ip.linodeusercontent.com/tos-alerts
else
  echo "No new tickets with subject line starting with 'ToS Violation'."
fi

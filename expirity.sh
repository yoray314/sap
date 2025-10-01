#!/usr/bin/env bash
#set -x

#NOTE: Consider making options for the script.

#NOTE: An assumption is made that the input file contains one website per line, as no specification was provided.
#make a list of websites from input file
mapfile -t websites_list < "$@"

for website in "${websites_list[@]}"; do
	#input from /dev/null is to prevent openssl from waiting for input
	#redirecting stderr to /dev/null is to suppress connection information
	certificate=$(openssl s_client -connect "${website}:443" < /dev/null 2>/dev/null)
	if [ $? -ne 0 ]; then
		echo "[FAILED] Could not connect to ${website} on port 443."
		continue
	fi
	expiry_date=$(openssl x509 -noout -enddate <<< "${certificate}")
	echo "[INFO] ${website} expires on: ${expiry_date}"
done

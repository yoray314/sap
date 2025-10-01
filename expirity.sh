#!/usr/bin/env bash
set -x

#NOTE: Consider making options for the script.

#NOTE: An assumption is made that the input file contains one website per line, as no specification was provided.
#make a list of websites from input file
mapfile -t websites_list < "$@"

for website in "${websites_list[@]}"; do
	#input from /dev/null is to prevent openssl from waiting for input
	#redirecting stderr to /dev/null is to suppress connection information
	certificate=$(openssl s_client -showcerts -connect "${website}:443" < /dev/null)
	if [ $? -ne 0 ]; then
		echo "[FAILED] Could not connect to ${website} on port 443."
		continue
	fi
	expiry_date=$(openssl x509 -noout -enddate <<< "${certificate}")
	#strip the "notAfter=" prefix
	expiry_date=${expiry_date#*=}
	echo "[INFO] ${website} expires on: ${expiry_date}"

	#check if certificate is revoked
	server_cert=$(awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/{if(/BEGIN CERTIFICATE/){i++}; if(i==1){print}}' <<< "${certificate}")
	issuer_cert=$(awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/{if(/BEGIN CERTIFICATE/){i++}; if(i==2){print}}' <<< "${certificate}")

	if [ -z "$server_cert" ] || [ -z "$issuer_cert" ]; then
		certificate_status="SKIPPED"
		continue
	fi

	echo "$server_cert" > server.pem
	echo "$issuer_cert" > issuer.pem

	ocsp_uri=$(openssl x509 -noout -ocsp_uri -in server.pem)

	if [ -z "$ocsp_uri" ]; then
		certificate_status="SKIPPED"
		rm server.pem issuer.pem
		continue
	fi

	ocsp_status=$(openssl ocsp -issuer issuer.pem -cert server.pem -url "$ocsp_uri" -text 2>/dev/null)

	if [[ "$ocsp_status" =~ "revoked" ]]; then
		certificate_status="REVOKED"
	elif [[ "$ocsp_status" =~ "good" ]]; then
		certificate_status="VALID"
	else
		certificate_status="UNKNOWN"
	fi

	rm server.pem issuer.pem
	#TODO: Set output message to include certificate status
	#TODO: Make output message based on thresholds
	#TODO: Switch to functions

	#NOTE: I have reduced the amount of pipelines for performance/readability but currently biggest bottleneck
	# are the web requests, I should consider using GNU Parallel. Or switching to Python :D
done

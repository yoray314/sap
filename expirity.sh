#!/usr/bin/env bash

get_cert() {
	#input from /dev/null is to prevent openssl from waiting for input
	#redirecting stderr to /dev/null is to suppress connection information
	certificate=$(openssl s_client -showcerts -connect "${website}:443" < /dev/null 2>/dev/null)

}

check_cert_validity() {
	#check if certificate is revoked
	server_cert=$(awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/{if(/BEGIN CERTIFICATE/){i++}; if(i==1){print}}' <<< "${certificate}")
	issuer_cert=$(awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/{if(/BEGIN CERTIFICATE/){i++}; if(i==2){print}}' <<< "${certificate}")

	if [ -z "$server_cert" ] || [ -z "$issuer_cert" ]; then
		certificate_status="SKIPPED"
		return
	fi

	server_file=$(mktemp)
	issuer_file=$(mktemp)

	echo "$server_cert" > "$server_file"
	echo "$issuer_cert" > "$issuer_file"

	ocsp_uri=$(openssl x509 -noout -ocsp_uri -in "$server_file")

	if [ -z "$ocsp_uri" ]; then
		certificate_status="SKIPPED"
		rm "$server_file" "$issuer_file"
		return
	fi

	ocsp_status=$(openssl ocsp -issuer "$issuer_file" -cert "$server_file" -url "$ocsp_uri" -text 2>/dev/null)

	if [[ "$ocsp_status" =~ "revoked" ]]; then
		certificate_status="REVOKED"
	elif [[ "$ocsp_status" =~ "good" ]]; then
		certificate_status="VALID"
	else
		certificate_status="UNKNOWN"
	fi

	rm "$server_file" "$issuer_file"
}

get_expiry_date() {
	expiry_date=$(openssl x509 -noout -enddate <<< "${certificate}")
	#strip the "notAfter=" prefix
	expiry_date=${expiry_date#*=}
}

#remove comment on next line for debugging
#set -x

#NOTE: Consider making options for the script.

#NOTE: An assumption is made that the input file contains one website per line, as no specification was provided.
#make a list of websites from input file
mapfile -t websites_list < "$@"

for website in "${websites_list[@]}"; do
(
	get_cert
	if [ $? -ne 0 ]; then
		echo "[FAILED] Could not connect to ${website} on port 443."
		exit 0
	fi

	check_cert_validity

	get_expiry_date

	#evaluate date in order to set better status messages
	expiry_date_epoch=$(date -u -d "$expiry_date" +%s)

	if [[ "$expiry_date_epoch" -lt "$(date -u +%s)" ]]; then
		echo "[EXPIRED] ${website} is ${certificate_status} and has expired on: ${expiry_date}"
	elif [[ "$expiry_date_epoch" -lt "$(date -u +%s -d '+30 days')" ]]; then
		echo "[WARNING] ${website} is ${certificate_status} and is expiring in less than 30 days on ${expiry_date}"
	else
		status_message="INFO"
		if [ "${certificate_status}" == "REVOKED" ]; then
			status_message="REVOKED"
		fi
		echo "[${status_message}] ${website} is ${certificate_status} and expires on: ${expiry_date}"
	fi
) &
sleep 0.1 #throttle the checks a bit to avoid overwhelming the system
done

# Wait for all background checks to finish
wait

#!/usr/bin/env bash
set -exo pipefail

mapfile -t websites_list < $@

for website in ${websites_list}; do
	#TODO: find a fix for the kept connection
	openssl s_client -connect ${website}:443
done

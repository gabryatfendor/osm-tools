#!/bin/bash

function encode_url_string() {
	if [ $# -ne 1 ]
		then
			echo "encode_url_string failed: wrong parameter number passed"
			return
	fi

	local length="${#1}"
	for (( i = 0; i < length; i++ )); do
		local c="${1:i:1}"
		case $c in
			[a-zA-Z0-9.~_-]) printf "$c" ;;
			*) printf '%%%02X' "'$c"
		esac
	done
	
}

function decode_url_string() {
	if [ $# -ne 1 ]
		then
			echo "decode_url_string failed: wrong parameter number passed"
			return
	fi

	local url_encoded="${1//+/ }"
	printf '%b' "${url_encoded//%/\\x}"
}

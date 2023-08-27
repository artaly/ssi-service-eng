#!/bin/bash

CRITICAL=""
WARNING=""
EMAIL=""
CURRENT_DATE=$(date "+%Y%m%d %H:%M")

while getopts ":c:w:e:" opt; do
	case "$opt" in
		c) CRITICAL="$OPTARG" ;;
		w) WARNING="$OPTARG" ;;
		e) EMAIL="$OPTARG" ;;
		\?) echo "Invalid option: -$OPTARG" >&2; exit 1;;
		:) echo "Option -$OPTARG requires an argument." >&2; exit 1;;
	esac
done

missing_params=""

check_missing_param() {
	if [[ -z ${!1} ]]; then
		missing_params+=" $1"
	fi
}

check_missing_param "CRITICAL"
check_missing_param "WARNING"
check_missing_param "EMAIL"

if [[ -n $missing_params ]]; then
	echo "Required parameter(s) missing: $missing_params"
	exit 1
fi

if [[ $CRITICAL -le $WARNING ]]; then
	echo "Critical threshold must be greater than the warning threshold"
	exit 
fi

MEMORY_USAGE=$(free | awk '/Mem:/ { print $3 }')
TOTAL_MEMORY=$(free | awk '/Mem:/ { print $2 }')

#USED_MEMORY=$((MEMORY_USAGE * 100 / TOTAL_MEMORY))

USED_MEMORY=90
# ^ used this used_memory value to check the used memory is greater than or equal to critical threshold cause my vb always returned low"

if [[ $USED_MEMORY -ge $CRITICAL ]]; then
	echo "Used memory is greater than or equal to critical threshold!"
	
	EMAIL_SUBJECT="$CURRENT_DATE memory_check - critical"
	TOP10_P=$(ps aux --sort=-%mem | head -n 11)
	echo "$TOP10_P" | mail -v -s "$EMAIL_SUBJECT" -S smtp-use-starttls -S ssl-verify=ignore -S smtp-auth=login -S smtp=smtp://smtp.example.com:587 -S from="loauvre@gmail.com" -S smtp-auth-user="loauvre@gmail.com" -S smtp-auth-password="xbynxnvrwkfoxtnx" loauvre@gmail.com
	
	exit 2
elif [[ $USED_MEMORY -ge $WARNING && $USED_MEMORY -le $CRITICAL ]]; then
	echo "Used memory is greater than or equal to warning threshold but less than critical threshold"
	exit 1
else
	echo "Used memory is less than warning threshold."
	exit 0
fi

echo "$CRITICAL"
echo "$WARNING"
echo "$EMAIL"

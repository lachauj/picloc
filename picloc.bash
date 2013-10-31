#!/usr/bin/env bash

test $# -lt 2 && echo "usage: $0 <path> <match>" && exit 1

export PATH="$PATH:/usr/bin/vendor_perl/"

DIR="$1"
MATCH="$2"

find "$DIR" -iname "$MATCH" | {
    while read str;
    do
	GPS=$( exiftool -n -c "%.6f degrees" "$str" | grep -i "gps position") 
	if [ "$GPS" != "" ];
	then
	    str=$(echo $str | sed -e 's/\ /%20/g')
	    echo "File: file://$str" 
	    ll=$(echo "$GPS" | cut -d ':' -f2 | sed -e 's/\ //' -e 's/\ /%2C/')
	    address=$(curl "http://maps.googleapis.com/maps/api/geocode/json?latlng=$ll&sensor=false" 2>/dev/null | grep -i "formatted_address" | head -n 1 | cut -d ':' -f2 | sed -e 's/\ "//' -e 's/",//')
	    echo "Address: $address"
	    echo -e "Maps url: https://www.google.fr/maps/preview#!q=$ll\n"
	fi
    done
}

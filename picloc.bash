#!/usr/bin/env bash

DIR="./"
MATCH="*.jpg"
FEH=0

function usage() {
    echo "usage: $0 [options [arg] ]"
    echo -e "\t-h display this help"
    echo -e "\t-x viewing with feh"
    echo -e "\t-p change default path (./)"
    echo -e "\t-x change default match (\"*.jpg\")"
}

function find_pics() {

    find "$DIR" -iname "$MATCH" | {
	while read str;
	do
	    GPS=$( exiftool -n -c "%.6f degrees" "$str" | grep -i "gps position" ) 
	    if [ "$GPS" != "" ]; then
		str_encode=$(echo $str | sed -e 's/\ /%20/g')
		ll=$(echo "$GPS" | cut -d ':' -f2 | sed -e 's/\ //' -e 's/\ /%2C/')
		address=$(curl "http://maps.googleapis.com/maps/api/geocode/json?latlng=${ll}&sensor=false" 2>/dev/null | grep -i "formatted_address" | head -n 1 | cut -d ':' -f2 | sed -e 's/\ "//' -e 's/",//')
		
		echo "File: file://$str_encode" 
		echo "Address: $address"
		echo -e "Maps url: https://www.google.fr/maps/preview#!q=$ll\n"
		
		if [ $FEH == 1 ]; then
		    feh --info "curl \"http://maps.googleapis.com/maps/api/geocode/json?latlng=${ll}&sensor=false\" 2>/dev/null | grep -i \"formatted_address\" | head -n 1 | cut -d ':' -f2 | sed -e 's/\ \"//' -e 's/\",//' -e 's/,\ /,/g' | tr ',' '\n'" "${str}" 2>/dev/null
		fi
	    fi

	    sleep 1
	done
    }
}

function main() {

    while getopts .xhp:m:. OPTION
    do
        case $OPTION in
                h)
		usage
		exit 0
		;;
                x)
                FEH=1
                ;;
                p)
		DIR=$OPTARG
                ;;
                m)
                MATCH=$OPTARG
                ;;
                ?)
                usage
                exit 1
                ;;
            esac
    done

    export PATH="$PATH:/usr/bin/vendor_perl/"

    find_pics
}

main "${@}"

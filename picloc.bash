#!/usr/bin/env bash

DIR="./"
MATCH="*.jpg"
FEH=0
CONVERT=0

function usage() {
    echo "usage: $0 [options [arg] ]"
    echo -e "\t-h display this help"
    echo -e "\t-x viewing with feh"
    echo -e "\t-c convert the image with location annotation"
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
		
		echo "[*] file: file://$str_encode" 
		echo "[*] address: $address"
		echo -e "[*] maps url: https://www.google.fr/maps/preview#!q=$ll\n"
		
		if [ $FEH == 1 ]; then
		    feh --info "curl \"http://maps.googleapis.com/maps/api/geocode/json?latlng=${ll}&sensor=false\" 2>/dev/null | grep -i \"formatted_address\" | head -n 1 | cut -d ':' -f2 | sed -e 's/\ \"//' -e 's/\",//' -e 's/,\ /,/g' | tr ',' '\n'" "${str}" 2>/dev/null
		fi

		if [ $CONVERT == 1 ]; then
		    convert "${str}" -gravity NorthWest -annotate 0 "$(echo $address | sed -e 's/,\ /,/g' | tr ',' '\n')"  $(basename "${str}" | sed -e 's/\(\.[A-Za-z]\{0,8\}$\)/-gps\1/')
		fi
	    fi
	    
	    sleep 1
	done
    }
}

function main() {

    while getopts .xchp:m:. OPTION
    do
        case $OPTION in
            h)
		usage
		exit 0
		;;
            x)
                FEH=1
                ;;
            c)
                CONVERT=1
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
    exiftool &>/dev/null
    test $? != 0 && echo "[*] exiftool is missing !" && exit 1
    find_pics
}

main "${@}"

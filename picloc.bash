#!/usr/bin/env bash

DIR="./"
MATCH="*.jpg"
FEH=0
CONVERT=0

function usage() {
    echo "usage: $0 [options [arg] ]"
    echo -e "\t-h display this help"
    echo -e "\t-x viewing with feh"
    echo -e "\t-c convert the image with a location annotation"
    echo -e "\t-p <path> change default path (./)"
    echo -e "\t-m <match> change default match (\"*.jpg\")"
}

function gps_deg_to_dec() {
    gps=$(identify -format "%[EXIF:*GPS*]" "$1" | grep -i "$2"= | cut -d '=' -f2 | sed -e 's/,/\ \+/' | sed -e 's/,/\ \* 1\/60\ \+ 1\/60\ \*\ 1\/60\ \*/')
    coeff=$(identify -format "%[EXIF:*GPS*]" "$1" | grep -i "$2"ref= | cut -d '=' -f2 | sed -e 's/[W|w|S|s]/\-1/' -e 's/[N|n|E|e]/1/')

    test "$gps" == "" && return 1

    echo "scale=10; (${gps}) * ${coeff}"  | bc

    return 0
}

function gps_position() {
    gpsLat=$(gps_deg_to_dec "$1" "latitude")
    gpsLon=$(gps_deg_to_dec "$1" "longitude")

    test $? == 1 && return 1

    echo "${gpsLat}%2C${gpsLon}"

    return 0
}

function starting_feh() {
    if [ $FEH == 1 ]; then
	feh -F --info "curl \"http://maps.googleapis.com/maps/api/geocode/json?latlng=$1&sensor=false\" 2>/dev/null | grep -i \"formatted_address\" | head -n 1 | cut -d ':' -f2 | sed -e 's/\ \"//' -e 's/\",//' -e 's/,\ /,/g' | tr ',' '\n'" "$2" 2>/dev/null
    fi
}

function converting_file() {
    cfile=$(readlink -f "$1" | sed -e 's/\ /%20/g')
    echo "[*] file: file://${cfile}" 
    cfile=$(echo "${cfile}" | sed -e 's/\(\.[A-Za-z]\{0,8\}$\)/-gps\1/')
    if [ $CONVERT == 1 ]; then
	convert "$1" -gravity NorthWest -annotate 0 "$(echo $address | sed -e 's/,\ /,/g' | tr ',' '\n')" "${cfile}"
	echo "[*] converted file: file://${cfile}"
    fi
}

function get_location() {
    address=$(curl "http://maps.googleapis.com/maps/api/geocode/json?latlng=${ll}&sensor=false" 2>/dev/null | grep -i "formatted_address" | head -n 1 | cut -d ':' -f2 | sed -e 's/\ "//' -e 's/",//')
    echo "[*] address: $address"
    echo "[*] maps url: https://www.google.fr/maps/preview#!q=${ll}"
}

function find_pics() {

    find "$DIR" -iname "$MATCH" | {
	while read file;
	do
	    ll=$(gps_position "${file}")
	    if [ $? == 0 ]; then
		converting_file "${file}"
		get_location "${ll}"
		starting_feh "${ll}" "${file}"
		echo 
		sleep 1
	    fi
	done
    }
}

function main() {

    while getopts xchp:m: OPTION
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

    find_pics
}

main "${@}"

#!/usr/bin/env bash

DIR="./"
MATCH="*.jpg"
FEH=0
SLIDESHOW=0
DIRECT=0
LOG_FILE=/tmp/pictures-infos-gps.log
CONVERT=0

function usage() {
    echo "usage: $0 [options [arg] ]"
    echo -e "\t-c convert the image with a location annotation"
    echo -e "\t-d desactivate pictures research (based on an old log file, required -x)"
    echo -e "\t-f <file> change default log file ($LOG_FILE)"
    echo -e "\t-h display this help"
    echo -e "\t-m <match> change default match (\"*.jpg\")"
    echo -e "\t-p <path> change default path (./)"
    echo -e "\t-s <seconds> activate slideshow"
    echo -e "\t-x viewing with feh"
}

function print_backspace()  {

    for ((j=0; j < $1; ++j))
    do
	echo -n -e "\b"
    done
}

function gps_deg_to_dec() {
    gps=$(identify -format "%[EXIF:*GPS*]" "$1" 2>/dev/null)
    gps=$(echo "$gps" | grep -i "$2"= | cut -d '=' -f2 | sed -e 's/,/\ \+/' | sed -e 's/,/\ \* 1\/60\ \+ 1\/60\ \*\ 1\/60\ \*/')
    test "$gps" == "" && return 1
    coeff=$(identify -format "%[EXIF:*GPS*]" "$1" | grep -i "$2"ref= | cut -d '=' -f2 | sed -e 's/[W|w|S|s]/\-1/' -e 's/[N|n|E|e]/1/')
    echo "scale=10; (${gps}) * ${coeff}"  | bc
    return 0
}

function gps_position() {
    gpsLat=$(gps_deg_to_dec "$1" "latitude")
    test $? == 1 && return 1
    gpsLon=$(gps_deg_to_dec "$1" "longitude")
    echo "${gpsLat}%2C${gpsLon}"

    return 0
}

function starting_feh() {
    if [ $FEH == 1 ]; then
	echo "[*] starting feh"
	feh -F -D $SLIDESHOW --info "echo %F | sed -e 's/\ /\\%20/g' | xargs -i grep -i -A 2 \"{}\" $LOG_FILE | grep -i address | cut -d ':' -f2 | sed -e 's/\ //' -e 's/,\ /,/g' | tr ',' '\n'" "$@"
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
    address=$(curl "http://maps.googleapis.com/maps/api/geocode/json?latlng=$1&sensor=false" 2>/dev/null | grep -i "formatted_address" | head -n 1 | cut -d ':' -f2 | sed -e 's/\ "//' -e 's/",//')
    echo "[*] address: $address"
    echo "[*] maps url: https://www.google.fr/maps/preview#!q=$1"
}

function parse_pics_found() {
    files=$(cat $LOG_FILE | grep -i file | cut -d ':' -f3 | sed -e 's/%20/\\ /g' | tr '\n' ' ')
    eval "starting_feh ${files}"
}

function find_pics() {

    declare -a files
    declare -a found

    files=( $(find "$DIR" -iname "$MATCH" | sed -e 's/\ /%20/g') )
    nbfiles=${#files[@]}

    echo -n "[*] completed: "

    for ((found=0, i=0; i < ${#files[@]}; ++i))
    do
	percent=$(echo "scale=2; ($i * 100) / ${nbfiles}" | bc)
	file=$(echo ${files[$i]} | sed -e 's/%20/\ /g')
	ll=$(gps_position "${file}")
	if [ $? == 0 ]; then
	    converting_file "${file}" >> $LOG_FILE
	    get_location "${ll}" >> $LOG_FILE
	    echo >> $LOG_FILE
	    found=$(( found + 1 ))
	fi
	infos=$(echo -n "${percent}% found: ${found}")
	echo -n $infos
	print_backspace $(echo -n $infos | wc -c) 
    done 

    echo "100% found: $i"
    echo "[*] log file created"
}

function main() {

    while getopts xcdhp:m:s:f: OPTION
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
            d)
		DIRECT=1
                ;;
            p)
		DIR=$OPTARG
                ;;
            m)
                MATCH=$OPTARG
                ;;
            f)
                LOG_FILE=$OPTARG
                ;;
            s)
                SLIDESHOW=$OPTARG
                ;;
            ?)
                usage
                exit 1
                ;;
            esac
    done

    if [ $DIRECT == 1 ]; then
	echo "[*] started in direct mode"
	test ! -f $LOG_FILE && echo "[*] $LOG_FILE is missing !" && exit 1 
	parse_pics_found
    else
	test -f $LOG_FILE && rm $LOG_FILE
	find_pics
    fi
}

main "${@}"

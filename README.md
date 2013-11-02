picloc
======

PICLOC (PICtures LOCation) is a pictures researcher to locate EXIF photos with GPS metadata.

### Required:
<ul>
	<li>ImageMagick</li>
  <li>Feh</li>
</ul>
### Usage example:<br>

Finds all pictures with gps metadata in *~/Private/pics/*, displays them with a slideshow of 3sec:
`./picloc.bash -p ~/Private/pics/ -x -s 3`

Displays all pictures based on an log file:
`./picloc.bash -d -f /tmp/file.log (if -f is missing, the default log file will be taken)`

Converts all pictures found (a copy named *basename*-gps.*extension* is created):<br>
`./picloc.bash -c -p ~/Private/pics/`

Help display `./picloc.bash -h`:

    usage: ./picloc.bash [options [arg] ]
       -c convert the image with a location annotation
       -d desactivate pictures research (based on an old log file, required -x)
       -f <file> change default log file (/tmp/pictures-infos-gps.log)
       -h display this help
       -m <match> change default match ("*.jpg")
       -p <path> change default path (./)
       -s <seconds> activate slideshow
       -x viewing with feh

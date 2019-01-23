#!/bin/bash

#Script that will list and format all the track that needs maintenance
#This information is taken from the tags maintenance and maintenance:it

#The structure is taken by monitor.sh script by user cascafico

#Usage: ./mantainme AREA-NAME outputFileName /path/for/output (--keep if you want to keep temp files, for debugging purpose)
#If the are name has spaces in it, double quote it

if [ $# -lt 3 ]
	then
		echo "Usage: ./mantainme AREA-NAME outputFileName /path/for/output (--keep if you want to keep temp files, for debugging purpose)"
		echo "If AREA-NAME has spaces in it, double quote it"
		exit
fi

AREA=$1
OUTPUT_FILENAME=$2
OUTPUT_PATH=$3

AREACODE=`curl -s "http://overpass-api.de/api/interpreter?data=area%5B%22boundary%22%3D%22administrative%22%5D%5B%22name%22%3D%22$AREA%22%5D%3Bout%20ids%3B%0A" | grep 3600 | awk -F "\"" '{print $2}'`

if [ -z $AREACODE ]
	then	
		echo "Area name not found, please double check"
		exit
fi

echo "Input area is $AREA"
echo "Related code is $AREACODE"


wget -nc -O $AREA.csv "http://overpass-api.de/api/interpreter?data=%5Bout%3Acsv%28%3A%3Aid%2C%22name%22%2C%22ref%22%2C%22maintenance%22%2C%22maintenance%3Ait%22%3Btrue%3B%22%3B%22%29%5D%3Barea%5B%22name%22%3D%22$AREA%22%5D-%3E.a%3Brelation%5B%22operator%22%7E%22CAI%22%5D%5B%22maintenance%22%5D%28area.a%29%3Brelation%5B%22operator%22%7E%22CAI%22%5D%5B%22maintenance%3Ait%22%5D%28area.a%29%3Bout%3B"

awk -F ";" 'FNR==1 {print $0} FNR > 1 { print "<a href=\"https://openstreetmap.org/relation/"$1"\">"$1"</a>",";"$2,";"$3,";"$4,";"$5 }' $AREA.csv > $AREA.tmp

echo "<h3>List of tracks in $AREA that needs maintenance<br><br>" > $OUTPUT_FILENAME.html
echo "<style>table, th, td { border: 1px solid black; border-collapse: collapse; }</style>" >> $OUTPUT_FILENAME.html
echo "<table><tr><th>Relation</th><th>Name</th><th>Ref Number</th><th>Maintenance</th><th>Maintenance:it</th></tr>" >> $OUTPUT_FILENAME.html

awk -F ";" ' NR>1 { print "<tr><td>"$1"</td><td>"$2"</td><td>"$3"</td><td>"$4"</td><td>"$5"</td></tr>"} ' $AREA.tmp >> $OUTPUT_FILENAME.html

if [ "$4" != "--keep" ]
	then
		echo "Removing temp file"
		rm $AREA.csv
		rm $AREA.tmp
fi

mv $OUTPUT_FILENAME.html $OUTPUT_PATH

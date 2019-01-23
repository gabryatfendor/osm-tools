#!/bin/bash

#Script that will list and format all the track that needs maintenance
#This information is taken from the tags maintenance and maintenance:it

#The structure is taken by monitor.sh script by user cascafico

#Usage: ./mantainme <area>
#If the are name has spaces in it, double quote it

if [ $# -eq 0 ]
	then
		echo "Usage: ./mantainme <area>"
		echo "If are name has spaces in it, double quote it"
		exit
fi

AREA=$1

AREACODE=`curl -s "http://overpass-api.de/api/interpreter?data=area%5B%22boundary%22%3D%22administrative%22%5D%5B%22name%22%3D%22$AREA%22%5D%3Bout%20ids%3B%0A" | grep 3600 | awk -F "\"" '{print $2}'`

if [ -z $AREACODE ]
	then	
		echo "Area name not found, please double check"
		exit
fi

echo "Input area is $AREA"
echo "Related code is $AREACODE"


wget -nc -O $1.csv "http://overpass-api.de/api/interpreter?data=%5Bout%3Acsv%28%3A%3Aid%2C%22name%22%2C%22ref%22%2C%22maintenance%22%2C%22maintenance%3Ait%22%3Btrue%3B%22%3B%22%29%5D%3Barea%5B%22name%22%3D%22$1%22%5D-%3E.a%3Brelation%5B%22operator%22%7E%22CAI%22%5D%5B%22maintenance%22%5D%28area.a%29%3Brelation%5B%22operator%22%7E%22CAI%22%5D%5B%22maintenance%3Ait%22%5D%28area.a%29%3Bout%3B"

awk -F ";" 'FNR==1 {print $0} FNR > 1 { print "<a href=\"https://openstreetmap.org/relation/"$1"\">"$1"</a>",";"$2,";"$3,";"$4,";"$5 }' $1.csv > $1.tmp

echo "<h3>List of tracks in $AREA that needs maintenance<br>" > maintenance.html
echo "<style>table, th, td { border: 1px solid black; border-collapse: collapse; }</style>" >> maintenance.html
echo "<table><tr><th>Relation</th><th>Name</th><th>Ref Number</th><th>Maintenance</th><th>Maintenance:it</th></tr>" >> maintenance.html

awk -F ";" ' NR>1 { print "<tr><td>"$1"</td><td>"$2"</td><td>"$3"</td><td>"$4"</td><td>"$5"</td></tr>"} ' $1.tmp >> maintenance.html

echo "Removing temp file"
rm tobemantained.lst
rm maintenance.xml

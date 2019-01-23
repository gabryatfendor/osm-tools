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

QUERY="http://overpass-api.de/api/interpreter?data=[out:xml][timeout:45];area($AREACODE)->.searchArea;relation[\"operator\"~\"CAI\"][\"maintenance\"](area.searchArea);relation[\"operator\"~\"CAI\"][\"maintenance:it\"](area.searchArea);(._;>;);out meta geom;"

wget -O maintenance.xml "$QUERY"

cat maintenance.xml | grep relation | awk -F "id=" ' { print $2 }'| awk -F "\"" ' { print $2 }' > tobemantained.lst

sort -u tobemantained.lst -o tobemantained.lst
MANT=`cat tobemantained.lst | wc -l`

echo "<h3>List of tracks in $AREA that needs maintenance" > maintenance.html
echo "<style>table, th, td { border: 1px solid black; border-collapse: collapse; }</style>" >> maintenance.html
echo "<table><tr><th>Relation</th><th>Maintenance</th><th>Maintenance:it</th></tr>" >> maintenance.html

#now reading the real data
while read -r line
do
	name="$line"
	echo "<tr><td><a href=\"https://www.openstreetmap.org/relation/$line\">$line</a></td><td></td><td></td></tr>" >> maintenance.html
done < "tobemantained.lst"

if [ $MANT == 0 ]
then
	echo "<tr><td colspan = \"3\">No trail to mantain. Good job!</td></tr>" >> maintenance.html
fi

echo "Removing temp file"
rm tobemantained.lst
rm maintenance.xml

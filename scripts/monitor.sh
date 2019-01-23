#!/bin/bash

source ../common/string-utils.sh
source ../common/osm-global-variables.sh

#Script created by cascafico -> https://github.com/cascafico/adiffq/

if [ $# -lt 4 ]
	then
		echo "Usage: ./monitor.sh <# of days ago to check> <area name (double quoted if with spaces)> <output filename> <output file path>"
     exit
fi

PLACE=$2
PLACE=${PLACE// /%20}
OUTPUT_FILE=$3.html
OUTPUT_PATH=$4

RUN=`date`
T0=`date -d "yesterday 00:00" '+%Y-%m-%d'`T00:00:00Z
T1=`date +"%Y-%m-%d"`T00:00:00Z

if [[ "$1" =~ ^[0-9]+$ ]] ; then 
   T0=`date -d "$1 days ago 00:00" '+%Y-%m-%d'`T00:00:00Z
   else echo "first argument must be an integer"
   exit
fi


AREACODE_QUERY=`encode_url_string "area[\"boundary\"=\"administrative\"][\"name\"=\"$PLACE\"];out ids;"`
AREACODE=`curl -s $OVERPASS_API_URL$AREACODE_QUERY | grep 3600 | awk -F "\"" '{print $2}'`
echo $PLACE
echo $AREACODE
if [ -z $AREACODE  ]
   then
     echo "area name not found (please case sensitive)"
     echo "...exiting"
     exit
fi

# here you can select relation tags
QUERY="$OVERPASS_API_URL[out:xml][timeout:45][adiff:\"$T0\",\"$T1\"];area($AREACODE)->.searchArea;relation[\"operator\"~\"CAI\"][\"ref\"](area.searchArea);(._;>;);out meta geom;"


echo "extracting CAIFVG differences ..."

wget -O adiff$OGGI.xml "$QUERY"

cat adiff$OGGI.xml | grep changeset | awk -F "changeset=" ' { print $2 }'| awk -F "\"" ' { print $2 }' > changeset.lst

echo "sorting and compacting changeset list"
sort -u changeset.lst -o changeset.lst
CHAN=`cat changeset.lst | wc -l`

echo "<h3>Changeset(s) created in interval</h3><br> Query:operator~CAI, ref existing <br> Area: $PLACE<br>Interval: since $1 days ago<p>" > $OUTPUT_FILE
echo "<style>table, th, td { border: 1px solid black; border-collapse: collapse; }</style>" >> $OUTPUT_FILE
echo "<table><tr><th>OSMcha</th><th>Achavi</th></tr>" >> $OUTPUT_FILE

while read -r line
do
    name="$line"
    echo "<tr><td><a href=\"https://osmcha.mapbox.com/changesets/$name?filters=%7B%22ids%22%3A%5B%7B%22label%22%3A%22$name%22%2C%22value%22%3A%22$name%22%7D%5D%7D\"> $line </a></td><td><a href=\"https://overpass-api.de/achavi/?changeset=$name\"> $line </a></td></tr>" >> $OUTPUT_FILE
done < "changeset.lst"

if [ $CHAN == 0 ]
then 
   echo "<tr><td colspan = \"2\">No changeset between $T0 and $T1</td></tr>" >> $OUTPUT_FILE
else
   echo "<tr><td colspan = \"2\">$CHAN changeset(s)  between $T0 and $T1</td></tr>" >> $OUTPUT_FILE
fi

echo "</table><p>This page has been generated on $RUN" >> $OUTPUT_FILE

echo "Removing temp file"
rm adiff.xml
rm changeset.lst

echo "Moving $OUTPUT_FILE to $OUTPUT_PATH"
mv $OUTPUT_FILE $OUTPUT_PATH

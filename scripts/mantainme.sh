#!/bin/bash

#Script that will list and format all the track that needs maintenance
#This information is taken from the tags maintenance and maintenance:it

#The structure is taken by monitor.sh script by user cascafico

#Usage: ./mantainme AREA-NAME outputFileName /path/for/output (--keep if you want to keep temp files, for debugging purpose)
#If the are name has spaces in it, double quote it

source ../common/string-utils.sh


if [ $# -lt 3 ]
	then
		echo "Usage: ./mantainme AREA-NAME outputFileName /path/for/output (--keep if you want to keep temp files, for debugging purpose)"
		echo "If AREA-NAME has spaces in it, double quote it"
		exit
fi

AREA=$1
OUTPUT_FILENAME=$2
OUTPUT_PATH=$3

OVERPASS_API_URL="http://overpass-api.de/api/interpreter?data="

AREACODE_QUERY=`encode_url_string "area[\"boundary\"=\"administrative\"][\"name\"=\"$AREA\"];out ids;"`
AREACODE=`curl -s $OVERPASS_API_URL$AREACODE_QUERY | grep 3600 | awk -F "\"" '{print $2}'`

if [ -z $AREACODE ]
	then	
		echo "Area name not found, please double check"
		exit
fi

echo "Input area is $AREA"
echo "Related code is $AREACODE"

CSV_QUERY=`encode_url_string "[out:csv(::id,\"name\",\"ref\",\"maintenance\",\"maintenance:it\";true;\";\")];area[\"name\"=\"$AREA\"]->.a;relation[\"operator\"~\"CAI\"][\"maintenance\"](area.a);relation[\"operator\"~\"CAI\"][\"maintenance:it\"](area.a);out;"`

wget -nc -O $AREA.csv $OVERPASS_API_URL$CSV_QUERY

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

#!/bin/bash

source ../common/string-utils.sh
source ../common/osm-global-variables.sh

#Script that will list and format all the track that needs to be surveyed again (you decide the interval between surveys as a parameter)
#This information is taken from the tags survey:date. If none is present, the route will be highlighted

if [ $# -lt 4 ]
	then
		echo "Usage: ./timetosurvey <area-name (double quoted if has spaces in it)> <days between surveys> <output filename> <output file path>"
		exit
fi

AREA=$1
SURVEY_INTERVAL=$2
OUTPUT_FILENAME=$3
OUTPUT_PATH=$4

AREACODE_QUERY=`encode_url_string "area[\"boundary\"=\"administrative\"][\"name\"=\"$AREA\"];out ids;"`
AREACODE=`curl -s $OVERPASS_API_URL$AREACODE_QUERY | grep 3600 | awk -F "\"" '{print $2}'`

if [ -z $AREACODE ]
	then	
		echo "Area name not found, please double check"
		exit
fi

echo "Input area is $AREA"
echo "Related code is $AREACODE"

CSV_QUERY=`encode_url_string "[out:csv(::id,\"name\",\"ref\",\"survey:date\";true;\";\")];area[\"name\"=\"$AREA\"]->.a;relation[\"operator\"~\"CAI\"](area.a);out;"`

wget -nc -O $AREA.csv $OVERPASS_API_URL$CSV_QUERY

awk -F ";" 'FNR==1 {print $0} FNR > 1 { print "<a href=\"https://openstreetmap.org/relation/"$1"\">"$1"</a>",";"$2,";"$3,";"$4 }' $AREA.csv > $AREA.tmp

echo "<h3>List of tracks in $AREA that needs to be surveyed<br><br>" > $OUTPUT_FILENAME.html
echo "<style>table, th, td { border: 1px solid black; border-collapse: collapse;} .urgent {color: red; font-weight: bold;}</style>" >> $OUTPUT_FILENAME.html
echo "<table><tr><th>Relation</th><th>Name</th><th>Ref Number</th><th>Last Known Survey Date</th></tr>" >> $OUTPUT_FILENAME.html

awk -F ";" '{ if (NR>1 && $4!="") print "<tr><td>"$1"</td><td>"$2"</td><td>"$3"</td><td>"$4"</td></tr>"; else if (NR>1 && $4=="") print "<tr><td>"$1"</td><td>"$2"</td><td>"$3"</td><td class=\"urgent\">No last known survey date!</td></tr>"; } ' $AREA.tmp >> $OUTPUT_FILENAME.html

echo "Removing temp file"
rm $AREA.csv
rm $AREA.tmp

mv $OUTPUT_FILENAME.html $OUTPUT_PATH

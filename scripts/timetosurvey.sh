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
OUTPUT_FILENAME=$3.html
OUTPUT_PATH=$4

echo "Checking for trail that were not surveyed in the last $SURVEY_INTERVAL days"
LIMIT_DATE=`date --date="$SURVEY_INTERVAL day ago" +%Y-%m-%d`

echo "So anything that was not surveyed after $LIMIT_DATE"

AREACODE_QUERY=`encode_url_string "area[\"boundary\"=\"administrative\"][\"name\"=\"$AREA\"];out ids;"`
AREACODE=`curl -s $OVERPASS_API_URL$AREACODE_QUERY | grep 3600 | awk -F "\"" '{print $2}'`

if [ -z $AREACODE ]
	then	
		echo "Area name not found, please double check"
		exit
fi

echo "Input area is $AREA"

CSV_QUERY=`encode_url_string "[out:csv(::id,ref,from,to,\"survey:date\";true;\";\")];area[name=\"$AREA\"]->.a;relation[operator~CAI](area.a);out;"`

echo "Downloading query result..."

wget -q -nc -O $AREA.csv $OVERPASS_API_URL$CSV_QUERY

awk -F ";" 'FNR==1 {print $0} FNR > 1 { print "<a href=\"https://openstreetmap.org/relation/"$1"\">"$1"</a>",";"$2,";"$3,";"$4, ";"$5 }' $AREA.csv > $AREA.tmp

echo "<h3>List of tracks in $AREA that needs to be surveyed</h3><br><br>" > $OUTPUT_FILENAME
echo "These tracks were not surveyed in the past $SURVEY_INTERVAL days, so they were all surveyed prior to $LIMIT_DATE<br>" >> $OUTPUT_FILENAME
echo "<style>table, th, td { border: 1px solid black; border-collapse: collapse;} .urgent {color: red; font-weight: bold;}</style>" >> $OUTPUT_FILENAME
echo "<table><tr><th>Relation</th><th>Ref Number</th><th>From</th><th>To</th><th>Last Known Survey Date</th></tr>" >> $OUTPUT_FILENAME

awk -v limit_date="$LIMIT_DATE" -F ";" '{ if (NR>1 && $5!="" && $5 <= limit_date) print "<tr><td>"$1"</td><td>"$2"</td><td>"$3"</td><td>"$4"</td><td>"$5"</td></tr>"; else if (NR>1 && $5=="") print "<tr><td>"$1"</td><td>"$2"</td><td>"$3"</td><td>"$4"</td><td class=\"urgent\">Never surveyed!</td></tr>"; } ' $AREA.tmp >> $OUTPUT_FILENAME

echo "</table>" >> $OUTPUT_FILENAME


echo "<br><br>Generated on `date`" >> $OUTPUT_FILENAME

echo "Removing temp file"
rm $AREA.csv
rm $AREA.tmp

mv $OUTPUT_FILENAME $OUTPUT_PATH

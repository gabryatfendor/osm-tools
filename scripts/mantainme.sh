#!/bin/bash

source ../common/string-utils.sh
source ../common/osm-global-variables.sh
#Script that will list and format all the track that needs maintenance
#This information is taken from the tags maintenance and maintenance:it

#The structure is taken by monitor.sh script by user cascafico

if [ $# -lt 3 ]
	then
		echo "Usage: ./mantainme <area-name (double quoted if has spaces in it)> <output filename> <output file path> < --keep if you want to keep temp files, for debugging purpose>"
		exit
fi

AREA=$1
OUTPUT_FILENAME=$2.html
OUTPUT_PATH=$3

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

echo "<h3>List of tracks in $AREA that needs maintenance</h3>" > $OUTPUT_FILENAME
echo "<style>table, th, td { border: 1px solid black; border-collapse: collapse; }</style>" >> $OUTPUT_FILENAME
echo "<table><tr><th>Relation</th><th>Name</th><th>Ref Number</th><th>Maintenance</th><th>Maintenance:it</th></tr>" >> $OUTPUT_FILENAME
awk -F ";" ' NR>1 { print "<tr><td>"$1"</td><td>"$2"</td><td>"$3"</td><td>"$4"</td><td>"$5"</td></tr>"} ' $AREA.tmp >> $OUTPUT_FILENAME
echo "</table>" >> $OUTPUT_FILENAME

echo "<br><br><footer>Generated on `date`</footer>" >> $OUTPUT_FILENAME

if [ "$4" != "--keep" ]
	then
		echo "Removing temp file"
		rm $AREA.csv
		rm $AREA.tmp
fi

mv $OUTPUT_FILENAME $OUTPUT_PATH

#!/bin/bash

source ../common/string-utils.sh
source ../common/osm-global-variables.sh

#Script that will list and format all the needed tag in a CAI  track (guidelines here -> https://wiki.openstreetmap.org/wiki/CAI#Sentieri)
#If a needed tag is missing it will be alerted in the table
if [ $# -lt 3 ]
	then
		echo "Usage: ./tagchecker <area-name (double quoted if has spaces in it)> <output filename> <output file path>"
		exit
fi

AREA=$1
OUTPUT_FILENAME=$2.html
OUTPUT_PATH=$3

AREACODE_QUERY=`encode_url_string "area[boundary=administrative][name=\"$AREA\"];out ids;"`
AREACODE=`curl -s $OVERPASS_API_URL$AREACODE_QUERY | grep 3600 | awk -F "\"" '{print $2}'`

if [ -z $AREACODE ]
	then	
		echo "Area name not found, please double check"
		exit
fi

echo "Input area is $AREA"

CSV_QUERY=`encode_url_string "[out:csv(::id,ref,from,to,network,name,cai_scale,roundtrip,source,\"osmc_symbol\",symbol,\"symbol:it\",operator,ascent,descent,distance,\"duration:forward\",\"duration:backward\",\"rwn:name\",\"ref:REI\",note,\"note:it\",website,\"note:project_page\";true;\";\")];area[name=\"$AREA\"]->.a;relation[type=route][route=hiking][operator=\"CAI Faenza\"](area.a);out;"`

echo "Downloading query result..."

wget -q -nc -O $AREA.csv $OVERPASS_API_URL$CSV_QUERY

awk -F ";" 'FNR==1 {print $0} FNR > 1 { print "<a href=\"https://openstreetmap.org/relation/"$1"\">"$1"</a>",";"$2,";"$3,";"$4, ";"$5, ";"$6, ";"$7, ";"$8,";"$9,";"$10, ";"$11, ";"$12, ";"$13,";"$14,";"$15, ";"$16, ";"$17, ";"$18,";"$19,";"$20, ";"$21, ";"$22, ";"$23, ";"$24 }' $AREA.csv > $AREA.tmp

echo "<h3>List of tracks mantained by CAI-Faenza and related tags</h3><br><br>" > $OUTPUT_FILENAME
echo "<style>table, th, td { border: 1px solid black; border-collapse: collapse;} .missing {color: red; font-weight: bold;}</style>" >> $OUTPUT_FILENAME
echo "<table><tr><th>Relation</th><th>Ref Number</th><th>From</th><th>To</th><th>Network</th><th>Name</th><th>CAI Scale</th><th>Roundtrip?</th><th>Source</th><th>OSMC Symbol</th><th>Symbol</th><th>Symbol:it</th><th>operator</th><th>Ascent</th><th>Descent</th><th>Distance</th><th>Duration:forward</th><th>Duration:backward</th><th>rwn:Name</th><th>ref:REI</th><th>note</th><th>Note:it</th><th>Website</th><th>Project Page</th></tr>" >> $OUTPUT_FILENAME

awk -v limit_date="$LIMIT_DATE" -F ";" '{ print "<tr><td>"$1"</td><td>"$2"</td><td>"$3"</td><td>"$4"</td><td>"$5"</td><td>"$6"</td><td>"$7"</td><td>"$8"</td><td>"$9"</td><td>"$10"</td><td>"$11"</td><td>"$12"</td><td>"$13"</td><td>"$14"</td><td>"$15"</td><td>"$16"</td><td>"$17"</td><td>"$18"</td><td>"$19"</td><td>"$20"</td><td>"$21"</td><td>"$22"</td><td>"$23"</td><td>"$24"</td></tr>"; } ' $AREA.tmp >> $OUTPUT_FILENAME

echo "</table>" >> $OUTPUT_FILENAME


echo "<br><br>Generated on `date`" >> $OUTPUT_FILENAME

echo "Removing temp file"
rm $AREA.csv
rm $AREA.tmp

mv $OUTPUT_FILENAME $OUTPUT_PATH

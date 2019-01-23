#!/bin/bash

source ../common/string-utils.sh
source ../common/osm-global-variables.sh

#first argument must be OSM area name (i.e. Trieste)
#REQUIRED csv2wiki python script (see wget below)

if [ $# -lt 2 ]
   then
     echo "Usage: ./relations-to-wiki <area-name (double quoted if with spaces)> <output file path>"
     exit
fi

OUTPUT_FILE_PATH=$2
wget -nc https://raw.githubusercontent.com/dlink/vbin/master/csv2wiki

CSV_QUERY=`encode_url_string "[out:csv(::id,\"name\",\"ref\",\"network\";true;\",\")];area[\"name\"=\"$1\"]->.a;relation[\"route\"=\"hiking\"][\"operator\"~\"CAI\"][\"ref\"](area.a);out;"`

echo $OVERPASS_API_URL$CSV_QUERY
wget -nc -O $1.csv $OVERPASS_API_URL$CSV_QUERY

#   extracted OSM csv file example:
#   @id,name,ref,network
#   9077889,,503,lwn
#   9079394,,500,lwn

awk -F "," 'FNR == 1  {print $0} FNR > 1 { print "[https://openstreetmap.org/relation/"$1" "$1"],"$2","$3","$4 }' $1.csv > $1.tmp
python csv2wiki $1.tmp > $1.wiki
echo "Removing temp file..."
rm $1.tmp
rm csv2wiki
rm $1.csv
echo "Moving $1.wiki to $OUTPUT_FILE_PATH"
mv $1.wiki $OUTPUT_FILE_PATH

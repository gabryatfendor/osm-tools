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

echo $T0
echo $T1

if [[ "$1" =~ ^[0-9]+$ ]] ; then 
   T0=`date -d "$1 days ago 00:00" '+%Y-%m-%d'`T00:00:00Z
   else echo "first argument must be an integer"
   exit
fi

AREACODE_QUERY=`encode_url_string "area[\"boundary\"=\"administrative\"][\"name\"=\"$PLACE\"];out ids;"`
AREACODE=`curl -s $OVERPASS_API_URL$AREACODE_QUERY | grep 3600 | awk -F "\"" '{print $2}'`
echo $PLACE
echo $AREACODE

# operator list (all the CAI sections in Emilia-Romagna
#CAI_SECTIONS=( "Bologna" "Argenta" "Carpi" "Castelfranco Emilia" "Castelnovo Ne' Monti" "Cesena" "Faenza" "Ferrara" "Forlì" "Imola" "Lugo" "Modena" "Parma" "Piacenza" "Porretta Terme" "Ravenna" "Reggio Emilia" "Rimini" "Sassuolo" "Pavullo" )
CAI_SECTIONS=( "Modena" )
echo "<h2>List of changes made yesterday on CAI trail network</h2>" > $OUTPUT_FILE

# here you can select relation tags
# we cycle all operators through the array
for operator in "${CAI_SECTIONS[@]}"
do
	githubstringexist=""
	while [[ "$githubstringexist" -lt 1 ]]
	do
		echo "1 minute cooldown to avoid api overload"
		sleep 60s
		QUERY="$OVERPASS_API_URL[out:xml][timeout:120][adiff:\"$T0\",\"$T1\"];area($AREACODE)->.searchArea;relation[\"operator\"=\"CAI $operator\"][\"ref\"](area.searchArea);(._;>;);out meta geom;"
		echo "extracting CAIFVG differences for CAI $operator ..."

		wget -O adiff$OGGI.xml "$QUERY"
	
		#remove all the previous versions
		sed -i '/<old>/,/<\/old>/d' adiff$OGGI.xml
		cat adiff$OGGI.xml | grep changeset > changeset.lst

		CHAN=`cat changeset.lst | wc -l`

		echo "<h3>Changeset(s) created in interval</h3><br> Query:operator=CAI $operator, ref existing <br> Area: $PLACE<br>Interval: since $1 days ago<p>" >> $OUTPUT_FILE
		echo "<style>table, th, td { border: 1px solid black; border-collapse: collapse; }</style>" >> $OUTPUT_FILE
		echo "<table><tr><th>Openstreetmap Object</th></tr>" >> $OUTPUT_FILE
		addtogithubstring=""
		while read -r line
		do
			timestamp=`echo $line | grep -oPm1 "(?<=timestamp)[^<]+" | awk '{print $1;}' | tr -d '=' | tr -d '"' | sed 's/[^0-9]//g'`
			timestamptocompare=`echo $T0 | sed 's/[^0-9]//g'`
			if [ $timestamp -ge $timestamptocompare ]
			then
				object_type=`echo $line | awk '{print $1;}' | tr -d '<'`
        		id=`echo $line | awk '{print $2;}' | tr -d 'id=' | tr -d '"'`
    			echo "<tr><td><a href=\"https://www.openstreetmap.org/$object_type/$id\">$object_type: $id</a></td></tr>" >> $OUTPUT_FILE
				addtogithubstring+="'"$object_type"' -> '"$id"'\n"
			fi
		done < "changeset.lst"
	
		#create a github issue
		githubstringexist=${#addtogithubstring}
		if [ $githubstringexist -gt 1 ]
		then
			curl -u "GITHUB_USERNAME":"GITHUB_TOKEN" https://api.github.com/repos/GITHUB_USERNAME/GITHUB_REPO/issues -d '{"title":"CAI '"$operator"' generated on '"$T1"'","body":"'"$addtogithubstring"'"}'
		fi	

		echo "Line was $githubstringexist long"
	done

	if [[ "$CHAN" -eq 0 ]]
	then 
   		echo "<tr><td>No changeset between $T0 and $T1</td></tr>" >> $OUTPUT_FILE
	else
   		echo "<tr><td>$CHAN changeset(s)  between $T0 and $T1</td></tr>" >> $OUTPUT_FILE
	fi

	echo "</table><p>This table has been generated on $RUN" >> $OUTPUT_FILE

	echo "Removing temp file"
	#rm adiff.xml
	rm changeset.lst
done

echo "Moving $OUTPUT_FILE to $OUTPUT_PATH"
mv $OUTPUT_FILE $OUTPUT_PATH

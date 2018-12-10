#!/bin/bash

#first argument must be OSM area name (i.e. Trieste)
#output wikitable with paths in local walking network (lwn)
#OSM csv extraction base on this query http://overpass-turbo.eu/s/Epu
#REQUIRED csv2wiki python script (see wget below)

wget -nc https://raw.githubusercontent.com/dlink/vbin/master/csv2wiki

if [ $# -eq 0 ]
   then
     echo "area name needed"
     echo "...exiting"
     exit
fi

wget -nc -O $1.csv "http://overpass-api.de/api/interpreter?data=%5Bout%3Acsv%28%3A%3Aid%2C%22name%22%2C%22ref%22%2C%22network%22%3Btrue%3B%22%2C%22%29%5D%3Barea%5B%22name%22%3D%22$1%22%5D%2D%3E%2Ea
%3Brelation%5B%22route%22%3D%22hiking%22%5D%5B%22network%22%3D%22lwn%22%5D%28area%2Ea%29%3Bout%3B%0A"

#   extracted OSM csv file example:
#   @id,name,ref,network
#   9077889,,503,lwn
#   9079394,,500,lwn

awk -F "," 'FNR == 1  {print $0} FNR > 1 { print "[https://openstreetmap.org/relation/"$1" "$1"],"$2","$3","$4 }' $1.csv > $1.tmp
python csv2wiki $1.tmp > $1.wiki
rm $1.tmp

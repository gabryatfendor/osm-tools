# osm-tools
Various scripts for OSM, related to CAI Emilia-Romagna section, but usable everywhere (since the area of search is parametric).

## Current available scripts

### mantainme.sh
Usage

```bash
./mantainme.sh <area-name (double quoted if has spaces in it)> <output filename> <output file path> < --keep if you want to keep temp files, for debugging purpose>
```

This script will create an html file that, reading the maintenance and maintenance:it, which trail with the operator CAI
are in needing of maintenance. It will output a table with all the needed informations

### monitor.sh
Usage

```bash
./monitor.sh <numbers of day ago to check> <area-name (double quoted if has spaces in it)>
```

This script will create an html file will all the changeset up to a specified number of days ago in the specified area.
It will output a table with links to the changesets

### relations-to-wiki.sh
Usage

```bash
./relations-to-wiki.sh <area-name (double quoted if with spaces)> <output file path>
```

This script will create a .wiki file with all the trail handled from CAI with id, name, ref and network. It can then be
copy/pasted in the OSM wiki

### timetosurvey.sh
Usage

```bash
./timetosurvey.sh <area-name (double quoted if has spaces in it)> <days between surveys> <output filename> <output file path>
```

This script will create an html file with a table where all the trail that, in the tag survey:date, have a date older than the
specified number of days (or no date at all)

### tagchecker.sh
Usage

```bash
./tagchecker <operator (double quoted if has spaces in it)> <output filename> <output file path>
```

This script create a table with the set of required tag for CAI relations (standards are here -> https://wiki.openstreetmap.org/wiki/CAI#Sentieri)
for the specified operator. In this way you can quickly check which tags are missing 

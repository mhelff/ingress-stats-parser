#!/bin/bash
#
# IngressStatisticsParser
# 
# Script for OCR on Ingress agent statistic screenshots.
#
# Copyright (C) 2014 Martin Helff
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later 
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT 
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with 
# this program. If not, see http://www.gnu.org/licenses/.
#
# Version 0.1 alpha: Produces a lot of temp files that are not cleaned up, 
# experimental use only!

function extractBox {
BOX=`grep -io "<span class='ocrx_word'[^>]*>$1</span>" stdout.html`
AT1=`echo $BOX | sed -E "s/.*bbox ([0-9]*) ([0-9]*) ([0-9]*) ([0-9]*).*/\1/"`
AT2=`echo $BOX | sed -E "s/.*bbox ([0-9]*) ([0-9]*) ([0-9]*) ([0-9]*).*/\2/"`
AT3=`echo $BOX | sed -E "s/.*bbox ([0-9]*) ([0-9]*) ([0-9]*) ([0-9]*).*/\3/"`
AT4=`echo $BOX | sed -E "s/.*bbox ([0-9]*) ([0-9]*) ([0-9]*) ([0-9]*).*/\4/"`
ATC1=`expr $AT3 - $AT1`
ATC2=`expr $AT4 - $AT2`

convert $4 -crop ${ATC1}x${ATC2}+${AT1}+${AT2} +repage $2
MEAN_VALUE=`identify -format "%[mean]" $2 | sed -E "s/([0-9,]*).*/\1/"`
echo $MEAN_VALUE
}

function maskAgentLogo {
BOX=`grep -o "<span class='ocrx_word'[^>]*>LVL[0-9]\{0,2\}</span>" stdout.html | head -n1`
AT1=`echo $BOX | sed -E "s/.*bbox ([0-9]*) ([0-9]*) ([0-9]*) ([0-9]*).*/\1/"`
AT2=`echo $BOX | sed -E "s/.*bbox ([0-9]*) ([0-9]*) ([0-9]*) ([0-9]*).*/\2/"`
AT3=`echo $BOX | sed -E "s/.*bbox ([0-9]*) ([0-9]*) ([0-9]*) ([0-9]*).*/\3/"`
AT4=`echo $BOX | sed -E "s/.*bbox ([0-9]*) ([0-9]*) ([0-9]*) ([0-9]*).*/\4/"`
LVLHEIGTH=`expr $AT4 - $AT2`
LOGODIST=`expr $LVLHEIGTH \* 170`
LOGODIST=`expr $LOGODIST / 100`
LOGOLOWERBORDER=`expr $AT4 + $LOGODIST`
LOGORBORDER=`expr $AT1 - 5`
convert $1 -fill black -stroke black -draw "rectangle 0,0,$LOGORBORDER,$LOGOLOWERBORDER" $2
}


function findAgentLine {
LINENUM=`awk '$0 ~ str{print NR FS b}{b=$0}' str="AGENT" $1`

if [[ $LINENUM ]];
then
  AGENTLINE=`expr $LINENUM + 2`
  else
  AGENTLINE="1"
fi
echo $AGENTLINE;
}

function extractAgentName {
AGENTLINE=`findAgentLine $1`
AGENTNAME=`sed "${AGENTLINE}!d" $1 | cut -f1 -d " "`
echo $AGENTNAME;
}

function extractAgentLevel {
AGENTLINE=`findAgentLine $1`
LEVELLINE=`expr $AGENTLINE + 1`
AGENTLEVEL=`sed "${LEVELLINE}!d" $1 | sed -E "s/.*LVL([0-9]*)/\1/"`
echo $AGENTLEVEL;
}

function findApLine {
LINENUM=`sed -e 's/\(.*\)/\U\1/' $1 | awk '$0 ~ str{print NR FS b}{b=$0}' str=".*AP.*AP.*" | cut -f1 -d " "`
echo $LINENUM
}

function extractAp {
APLINE=`findApLine $1`
AGENTAP=`sed "${APLINE}!d" $1 | sed -E "s/([0-9,]*) .*/\1/" | sed "s/,//g"`
echo $AGENTAP
}

function getOwnForeignStats {
LINENUM=`awk '$0 ~ str{print NR FS b}{b=$0}' str="AGENT" $1`

if [[ $LINENUM ]];
then
  OWNFOREIGN="own"
  else
  OWNFOREIGN="foreign"
fi
echo $OWNFOREIGN;
}

function echoStatsPlain {
  echoStatsInternal "%s=%s"
}

function echoStatsHuman {
hd[TYPE]="Type of stats"
hd[OWNFOREIGN]="Own or foreign"
hd[AGENT]="Agent"
hd[LEVEL]="Level"
hd[AP]="AP"
hd[UPV]="Unique Portals Visited"
hd[PD]="Portals discovered"
hd[XMC]="XM Collected"
hd[HACKS]="Hacks"
hd[RDEPLOY]="Resonators Deployed"
hd[LC]="Links created"
hd[CFC]="Control Fields Created"
hd[MUC]="Mind Units Captured"
hd[LLEC]="Longest Link Ever Created"
hd[LCF]="Largest Control Field"
hd[XMR]="XM Recharged"
hd[PC]="Portals Captured"
hd[UPC]="Unique Portals Captured"
hd[RDESTROY]="Resonators Destroyed"
hd[PN]="Portals Neutralized"
hd[ELD]="Enemy Links Destroyed"
hd[ECFD]="Enemy Control Fields Destroyed"
hd[DW]="Distance Walked"
hd[MTPH]="Max Time Portal Held"
hd[MTLM]="Max Time Link Maintained"
hd[MLLD]="Max Link Length x Days"
hd[MTFH]="Max Time Field Held"
hd[LFMD]="Largest Field MUs x Days"
hd[MODDEP]="Mods Deployed"

echoStatsInternal "%s: %s" 
}

function echoStatsJson {
echo "{ \"statsentry\": {"
echoStatsInternal "\\\"%s\\\": \\\"%s\\\","
echo "} }"
}

function echoStatsInternal {
for key in "${!results[@]}"
do
  
  if test "${hd[$key]+isset}"
  then
     KEYVAL=${hd[$key]}
  else
     KEYVAL=$key
     #echo "KEYVAL: $KEYVAL" >&2
  fi
  OUTPUTLINE=`printf "$1" "$KEYVAL" "${results[$key]}"`
  echo "$OUTPUTLINE"
done
}

function show_help {
   echo "Ingress stats parser"
   echo
   echo "Usage: isp.sh [options...] imagefile"
   echo
   echo "Options:"
   echo "-f plain|json|human   output format selection"
   echo "-h                    show this help message"
}

function doOCR {

convert $1 -white-threshold 20000 orgbw.png
tesseract orgbw.png stdout -l eng -psm 4 hocr 1> stdout.html 2>/dev/null
maskAgentLogo orgbw.png withoutlogo.png


M1=`extractBox ALL[TIME]* b1.png b1.txt $1`
M2=`extractBox MONTH b2.png b2.txt $1`
M3=`extractBox WEEK b3.png b3.txt $1`
M4=`extractBox NOW b4.png b4.txt $1`

if [ $M1 \> $M2 ] && [ $M1 \> $M3 ] &&  [ $M1 \> $M4 ];
then
TYPE="ALLTIME";
fi;
if [ $M2 \> $M1 ] && [ $M2 \> $M3 ] &&  [ $M2 \> $M4 ];
then
TYPE="MONTH";
fi;
if [ $M3 \> $M1 ] && [ $M3 \> $M2 ] &&  [ $M3 \> $M4 ];
then
TYPE="WEEK";
fi;
if [ $M4 \> $M1 ] && [ $M4 \> $M2 ] &&  [ $M4 \> $M3 ];
then
TYPE="NOW";
fi;

# now fetch the stats
tesseract withoutlogo.png stdout -l eng -psm 4 > stdout.txt

results[TYPE]=$TYPE
results[IMAGE]=$1
results[AGENT]=`extractAgentName stdout.txt`
results[LEVEL]=`extractAgentLevel stdout.txt`
results[AP]=`extractAp stdout.txt`
results[OWNFOREIGN]=`getOwnForeignStats stdout.txt`
results[UPV]=`grep "Unique Portals Visited" stdout.txt | sed -E "s/.* ([0-9,]*)/\1/" | sed "s/,//g"`
results[PD]=`grep "Portals Discovered" stdout.txt | sed -E "s/.* ([0-9,]*)/\1/" | sed "s/,//g"`
results[XMC]=`grep "XM Collected" stdout.txt | sed -E "s/.* ([0-9,]*) .*/\1/" | sed "s/,//g"`
results[HACKS]=`grep "Hacks" stdout.txt | sed -E "s/.* ([0-9,]*)/\1/" | sed "s/,//g"`
results[RDEPLOY]=`grep "Resonators Deployed" stdout.txt | sed -E "s/.* ([0-9,]*)/\1/" | sed "s/,//g"`
results[LC]=`grep "Links Created" stdout.txt | sed -E "s/.* ([0-9,]*)/\1/" | sed "s/,//g"`
results[CFC]=`grep "Control Fields Created" stdout.txt | sed -E "s/.* ([0-9,]*)/\1/" | sed "s/,//g"`
results[MUC]=`grep "Mind Units Captured" stdout.txt | sed -E "s/.* ([0-9,]*) .*/\1/" | sed "s/,//g"`
results[LLEC]=`grep "Longest Link Ever Created" stdout.txt | sed -E "s/.* ([0-9,]*) .*/\1/" | sed "s/,//g"`
results[LCF]=`grep "Largest Control Field" stdout.txt | sed -E "s/.* ([0-9,]*) .*/\1/" | sed "s/,//g"`
results[XMR]=`grep "XM Recharged" stdout.txt | sed -E "s/.* ([0-9,]*) .*/\1/" | sed "s/,//g"`
results[PC]=`grep "^Portals Captured" stdout.txt | sed -E "s/.* ([0-9,]*)/\1/" | sed "s/,//g"`
results[UPC]=`grep "Unique Portals Captured" stdout.txt | sed -E "s/.* ([0-9,]*)/\1/" | sed "s/,//g"`
results[RDESTROY]=`grep "Resonators Destroyed" stdout.txt | sed -E "s/.* ([0-9,]*)/\1/" | sed "s/,//g"`
results[PN]=`grep "Portals Neutralized" stdout.txt | sed -E "s/.* ([0-9,]*)/\1/" | sed "s/,//g"`
results[ELD]=`grep "Enemy Links Destroyed" stdout.txt | sed -E "s/.* ([0-9,]*)/\1/" | sed "s/,//g"`
results[ECFD]=`grep "Enemy Control Fields Destroyed" stdout.txt | sed -E "s/.* ([0-9,]*)/\1/" | sed "s/,//g"`
results[DW]=`grep "Distance Walked" stdout.txt | sed -E "s/.* ([0-9,]*) .*/\1/" | sed "s/,//g"`
results[MTPH]=`grep "Portal Held" stdout.txt | sed -E "s/.* ([0-9,]*) .*/\1/" | sed "s/,//g"`
results[MTLM]=`grep "Link Maintained" stdout.txt | sed -E "s/.* ([0-9,]*) .*/\1/" | sed "s/,//g"`
results[MLLD]=`grep "Length x Days" stdout.txt | sed -E "s/.* ([0-9,]*) .*/\1/" | sed "s/,//g"`
results[MTFH]=`grep "Field Held" stdout.txt | sed -E "s/.* ([0-9,]*) .*/\1/" | sed "s/,//g"`
results[LFMD]=`grep "Largest Field" stdout.txt | sed -E "s/.* ([0-9,]*) .*/\1/" | sed "s/,//g"`
results[MODDEP]=`grep "Mods Deployed" stdout.txt | sed -E "s/.* ([0-9,]*)/\1/" | sed "s/,//g"`

}

declare -A results
declare -A hd
output_format="human"

if [ $# -eq 0 ]
then
   show_help
   exit 0
fi

while getopts "hf:" opt; do
    case "$opt" in
     h) show_help
        exit 0
        ;;
    f)  output_format=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

doOCR $1

case "$output_format" in
    plain) echoStatsPlain
        ;;
    json) echoStatsJson
        ;;
    human) echoStatsHuman
        ;;esac

#echoStatsJson
#echoStatsHuman
#echoStatsPlain

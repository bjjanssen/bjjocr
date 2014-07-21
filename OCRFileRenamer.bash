#!/bin/bash

# This is a simple OCR-based file renamer.
# Last modified 2014-07-21 bjoern.janssen

### Globals ###

UZN_id="1900 50 250 50 PerNR"
UZN_Mon="1500 50 250 50 Month"
UZN_Year="1700 50 250 50 Year"
NN="NoName"
EXT=".pdf"
DOC="LA"
MM="05"
YYYY="2014"

BASEPATH="/mnt/HR_scan_import_to_kiss/LA"
WORKINGDIR="/opt"
INPATH="/opt/Import/LA"
OUTPATH="/opt/Export/LA"
DONE="/opt/Done/LA"

function createWorkingArea {

	if ! [ -d $INPATH ]
	then
		mkdir -p $INPATH
	fi

	if ! [ -d $OUTPATH ]
	then
		mkdir -p $OUTPATH
	fi

	if ! [ -d $DONE ]
	then
		mkdir -p $DONE
	fi
	
	echo "$(date +%F_%T) BEGIN"
	for f in ${INPATH}/*.pdf
	do 
		echo "$(date +%F_%T) Processing $f"
		pre=$(basename $f .pdf)
		# PDFTK
		pdftk $f burst output ${pre}_%05d.pdf
		worker $pre
		mv $f $DONE
	done
}

function worker {
	pre=$1
	for file in ${pre}*.pdf
	do
		base=$(basename $file .pdf)
		convert -depth 8 -density 300 -trim -strip $file $base.tiff
		uzn_ID
		
		NN="${DOC}_${MM}_${YYYY}_$persid"

		rm -f $base.tiff 
		rm -f $base.uzn
		rm -f id_$base.txt

		count=1
		FNN=$NN$EXT
		
		while [[ -e ${OUTPATH}/$FNN ]]
		do
			incr=$(printf "%03d" $count)
			FNN="$NN.$incr"
			let count=count+1
		done

		mv -n -v $file ${OUTPATH}/$FNN

	done
}

function uzn_ID {
	echo $UZN_id > $base.uzn
	ocr $base.tiff id_$base deu 4

#	
#	todo:
#	Ist die letzte Stelle eine 1, wird sie als "l" erkannt.
#

	persid=$(grep -P '[0-9]{4,8}' id_$base.txt)
	
}

function uzn_Mon {
	echo $UZN_Mon > $base.uzn
	ocr $base.tiff Mon_$base deu 4
	tmpMon=$(grep -P '[A-z][a-z]{3,8}' Mon_$base.txt)
	
	case $tmpMon in
		Januar|January)
			MM="01"
			;;
		Februar|February)
			MM="02"
			;;
		März|Maerz|March)
			MM="03"
			;;
		April)
			MM="04"
			;;
		Mai|May)
			MM="05"
			;;
		Juni|June)
			MM="06"
			;;
		Juli|July)
			MM="07"
			;;
		August)
			MM="08"
			;;
		September|Septembre)
			MM="09"
			;;
		Oktober|October)
			MM="10"
			;;
		November|Novembre)
			MM="11"
			;;
		Dezember|Decembre|December)
			MM="12"
			;;
		*)
			MM=$(date +%m)
}

function uzn_Year {
	echo $UZN_Year > $base.uzn
	ocr $base.tiff Year_$base deu 4
	YYYY=$(grep -P '[0-9]{4}' Year_$base.txt)
}

function ocr {
	input=$1
	output=$2
	lang=$3
	level=$4
	tesseract $input $output -l $lang -psm $level &> /dev/null
}

function mergeSameIDs {
#
#	todo: Fehler abfangen!
#

	echo "Start Merge"
	cd $OUTPATH
	for f in *.001
	do
        	base=$(basename $f .001)
	        pdftk ${base}.* cat output complete_${base}.pdf
        	
		rm -f ${base}.*
	        mv -n -v complete_${base}.pdf ${base}.pdf
	done
	echo "Finished Merge"
}

cd $WORKINGPATH
createWorkingArea
mergeSameIDs
echo "$(date +%F_%T) END"
exit


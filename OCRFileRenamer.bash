#!/bin/bash

# This is a simple OCR-based file renamer.
# Last modified 2014-07-21 bjoern.janssen

### Settings ###
### true/false

enable_UZN_ID=true
enable_UZN_MM=false
enable_UZN_YYYY=false

### Globals ###

UZN_ID="1900 50 250 50 PerNR"
UZN_MM="1500 50 250 50 Month"
UZN_YYYY="1700 50 250 50 Year"
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
#
#	Abgeschaltete uzn sind noch nicht korrekt vermessen.
#
		if [ $enable_UZN_ID = "true" ]
		then
			uzn_ID
		fi

		if [ $enable_UZN_MM = "true" ]
		then
			uzn_MM		
		fi

		if [ $enable_UZN_YYYY = "true" ]
		then
			uzn_YYYY
		fi

		NN="${DOC}_${MM}_${YYYY}_$persid"

		rm -f $base.tiff 
		rm -f $base.uzn

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
	echo $UZN_ID > $base.uzn
	ocr $base.tiff ID_$base deu 4

#	
#	Fieser hack! Richtig wäre es, wenn wir tesseract auf bessere l/1 Erkennung trainieren würden.
#	https://code.google.com/p/tesseract-ocr/wiki/TrainingTesseract3
#

	cat ID_$base.txt | tr l 1 > ID_$base.txt2
	persid=$(grep -P '[0-9]{4,8}' ID_$base.txt2)
	rm -f ID_$base.txt*
}

function uzn_MM {
	echo $UZN_MM > $base.uzn
	ocr $base.tiff MM_$base deu 4
	tmpMM=$(grep -P '[A-z][a-z]{3,8}' MM_$base.txt)
	
	case $tmpMM in
		Januar|January)
			MM="01"
			;;
		Februar|February)
			MM="02"
			;;
		März|Maerz|Marz|March)
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
	esac
	
	rm -f MM_$base.txt
}

function uzn_YYYY {
	echo $UZN_YYYY > $base.uzn
	ocr $base.tiff YYYY_$base deu 4
	YYYY=$(grep -P '[0-9]{4}' YYYY_$base.txt)
	rm -f YYYY_$base.txt
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
		echo "$(date +%F_%T) Merging $base"
		
	        pdftk ${base}.* cat output merged_${base}.pdf
        	
		rm -f ${base}.*
	        mv -n -v merged_${base}.pdf ${base}.pdf
	done
	echo "Finished Merge"
}

cd $WORKINGPATH
createWorkingArea
mergeSameIDs
echo "$(date +%F_%T) END"
exit


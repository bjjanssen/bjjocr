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
		echo $UZN_id > $base.uzn
		convert -depth 8 -density 300 -trim -strip $file $base.tiff
		ocr $base.tiff id_$base deu 4

		persid=$(grep -P '[0-9]{4,8}' id_$base.txt)
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

function ocr {
	input=$1
	output=$2
	lang=$3
	level=$4
	tesseract $input $output -l $lang -psm $level &> /dev/null
}

function mergeSameIDs {
	echo "Start Merge"
	cd $OUTPATH
	for f in *.001
	do
        	base=$(basename $f .001)
	        pdftk ${base}.* cat output complete_${base}.pdf
        	mv -v ${base}.* joined/
	        mv -n -v complete_${base}.pdf ${base}.pdf
	done
	echo "Finished Merge"
}

cd $WORKINGPATH
createWorkingArea
mergeSameIDs
echo "$(date +%F_%T) END"
exit


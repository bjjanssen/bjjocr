#!/bin/bash

# This is a simple OCR-based file renamer.
# Last modified 2014-07-20 bjoern.janssen

### Globals ###

UZN="1900 50 250 50 PerNR"
NN="NoName"
EXT=".pdf"
INPATH="./Import"
OUTPATH="./Export"
DONE="./Done"

function createWorkingArea {
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
		echo $UZN > $base.uzn
		convert -depth 8 -density 300 -trim -strip $file $base.tiff
		ocr $base.tiff tmp_$base deu 4

		persid=$(grep -P '[0-9]{4,8}' tmp_$base.txt)
		NN="LA_06_2014_$persid"

		rm -f $base.tiff 
		rm -f $base.uzn
		rm -f tmp_$base.txt

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
	for f in *.001
	do
        	base=$(basename $f .001)
	        pdftk ${base}.* cat output complete_${base}.pdf
        	mv -v ${base}.* joined/
	        mv -n -v complete_${base}.pdf ${base}.pdf
	done
	echo "Finished Merge"
}

createWorkingArea
mergeSameIDs
echo "$(date +%F_%T) END"
exit


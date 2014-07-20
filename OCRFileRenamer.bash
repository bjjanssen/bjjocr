#!/bin/bash

# This is a simple OCR-based file renamer.
# Last modified 2014-07-20 bjoern.janssen

### Globals ###

UZN="1900 50 250 50 PerNR"
NN="NoName"
EXT=".pdf"

# Later we want to run several renamers in parallel. The simplest way to do so with BASH is to start several processes. 
#
# burstPDF $f dir_$t &
#
# Beware, this can make your machine unresponsive if you have several PDFs with many pages (>1000). 

function createWorkingArea {
	mkdir Vorlagen
	for f in *.pdf
	do 
		pre=$(basename $f .pdf)
		# PDFTK
		pdftk $f burst output ${pre}_%05d.pdf
		mv $f Vorlagen/
		worker $pre

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
		echo $number
		NN="LA_06_2014_$persid"

		rm -f $base.tiff 
		rm -f $base.uzn
		rm -f tmp_$base.txt

		count=1
		FNN=$NN$EXT
		
		while [[ -e $FNN ]]
		do
			incr=$(printf "%03d" $count)
			FNN="$NN.$incr"
			let count=count+1
		done

		mv -n -v $file $FNN
	done
}

function ocr {
	input=$1
	output=$2
	lang=$3
	level=$4
	tesseract $input $output -l $lang -psm $level &> /dev/null
}

createWorkingArea
exit


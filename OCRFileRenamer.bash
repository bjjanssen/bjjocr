#!/bin/bash

# This is a simple OCR-based file renamer.
# 1) Install required packages
#
# $apt-get install tesseract-ocr tesseract-ocr-<yourlanguage> imagemagick pdftk
#
# 2) Convert your source file to a tiff-image with imagemagick's convert tool. The tiff must fullfill the following requirement
# * 300dpi
# * 8 bit colordepth
#
# I recommend stripping and trimming, too.
#
# $convert -depth 8 -density 300 -strip -trim input.pdf output.tiff
#
# 3) Use zonal OCR with tesseract. 
#
# Create an uzn file to define a zone. 
# The uzn file must have the same name as the input file, e.g input file = input.tiff then the uzn file must be named input.uzn
# The uzn file format is:
# x-coordinate y-coordinate width height identifier
#
# The x- and y-coordinates define the top left corner of a rectangle. 
# Width and height define the dimensions of the rectangle. 
# The identifier is unused and currently only helps the user in remembering the defined zone.
# All parameters must one space apart.
#
# You can define several zones, but only the first one is used.
#
# $tesseract input.tiff - -l <yourlanguage> -psm 4 
#
# Instead of stdout you can use a filename.
#
############################################

function createWorkingDirs {
	for f in *.pdf
	do 
		t=$(basename $f .pdf)
		mkdir dir_$t
		mv $f dir_$t
		burstPDF $f dir_$t &
	done
}

function burstPDF {
	file=$1
	dir=$2
	cd $dir
	pdftk $file burst
	startWorker
}

function startWorker {
	for f in *.pdf
	do
		renamePDF $f &
	done
}

function checkDoubles {
	name=$1
	let count=0
	incr=($printf "%05d" $count)

	if [ -e $name ]
	then 
		n=$(basename $newname .pdf)
		newname="$n $incr.pdf"
		let count=count+1
		checkDoubles $newname
	else
		break
	fi
}

function renamePDF {
	file=$1
	base=$(basename $f .pdf)
	convert -depth 8 -density 300 -trim -strip $file $base.tiff
	ocr $base.tiff tmp_$base deu 4

	PersID=$(grep -P '[0-9]{4,8}' tmp_$base.txt)
	
	nn="LA_06_2014_$PersID.pdf"

	checkDoubles $nn

	mv -n -v $file $nn
	rm -f $base.tiff 
}

function ocr {
	input=$1
	output=$2
	lang=$3
	level=$4
	tesseract $input $output -l $lang -psm $level
}


createWorkingDirs
exit


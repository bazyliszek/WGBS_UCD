#!/bin/bash

echo "$0"
echo "$(date -I)"

if [ $# -lt 1 ]; then
	echo "Usage: $0 <rootdir> [CSVfile]"
	exit 1
fi

cwd=`pwd`
echo "cwd: $cwd"

rootdir=$1
echo "rootdir: $rootdir"

if [ -z $2 ]; then
	outfolder='log'
	CSVfile=$outfolder/"$(basename $0 | sed -e "s/\.sh/_$(date -I).csv/")"
else
	CSVfile=$2
	outfolder=$(dirname $CSVfile)
fi
echo "CSVfile: $CSVfile"

if [ ! -e $outfolder ]; then
	mkdir -pv $outfolder
fi

# List unique folders that contain report files
folders=`find $rootdir -name '*_report.txt' -exec dirname {} \; | \
	sort | uniq`
echo -e "folders (next line):\n$folders"

str_perc="([0-9\.]*)%.*"
str_count="([[:digit:]]*)"

# Adapt below to seemlessly process single- and paired-end files
str_read_in="Sequence pairs analysed in total:[[:space:]]*"
str_unique="Number of paired-end alignments with a unique best hit:[[:space:]]*"
str_efficiency="Mapping efficiency:[[:space:]]*"
str_unaligned="Sequence pairs with no alignments under any condition:[[:space:]]*"
str_multimap="Sequence pairs did not map uniquely:[[:space:]]*"
str_seq_issue="Sequence pairs which were discarded because genomic sequence could not be extracted:[[:space:]]*"
str_OT_start="CT\/GA\/CT:[[:space:]]*"
str_OT_end="[[:space:]]*\(\(converted\) top strand\)"
str_CTOT_start="GA\/CT\/CT:[[:space:]]*"
str_CTOT_end="[[:space:]]*\(complementary to \(converted\) top strand\)"
str_CTOB_start="GA\/CT\/GA:[[:space:]]*"
str_CTOB_end="[[:space:]]*\(complementary to \(converted\) bottom strand\)"
str_OB_start="CT\/GA\/GA:[[:space:]]*"
str_OB_end="[[:space:]]*\(\(converted\) bottom strand\)"

echo "$str_OB_start$str_count$str_OB_end"

# Function to extract relevant info from file
extract_info(){
	if [ $# -lt 1 ]; then
		echo "Usage: $0 <report.txt>"
		exit 1
	fi
	input_read=$(grep "$str_read_in" $1 | 
		perl -pe "s/$str_read_in$str_count/\1/")
	unique_read=$(grep "$str_unique" $1 | 
		perl -pe "s/$str_unique$str_count/\1/")
	efficiency=$(grep "$str_efficiency" $1 | 
		perl -pe "s/$str_efficiency$str_perc/\1/")
	unaligned=$(grep "$str_unaligned" $1 | 
		perl -pe "s/$str_unaligned$str_count/\1/")
	multimap=$(grep "$str_multimap" $1 | 
		perl -pe "s/$str_multimap$str_count/\1/")
	seq_issue=$(grep "$str_seq_issue" $1 | 
		perl -pe "s/$str_seq_issue$str_count/\1/")
	OT=$(grep -E "$str_OT_end" $1 | 
		perl -pe "s/$str_OT_start$str_count$str_OT_end/\1/")
	CTOT=$(grep -E "$str_CTOT_end" $1 | 
		perl -pe "s/$str_CTOT_start$str_count$str_CTOT_end/\1/")
	CTOB=$(grep -E "$str_CTOB_end" $1 | 
		perl -pe "s/$str_CTOB_start$str_count$str_CTOB_end/\1/")
	OB=$(grep -E "$str_OB_end" $1 | 
		perl -pe "s/$str_OB_start$str_count$str_OB_end/\1/")
	# return the result
	echo "$input_read\",\"$unique_read\",\"$efficiency\",\"$unaligned\",\"\
$multimap\",\"$seq_issue\",\"$OT\",\"$CTOT\",\"$CTOB\",\"$OB"
}

for folder in `echo $folders`
do
	echo "folder: $folder"
	# Identify the batch to annotate the output metrics
	batch=$(basename $folder)
	echo "batch: $batch"
	# Identify all the forward reads in the folder
	report1s=$(find $folder -name '*_report.txt')
	echo -e "folders (next line):\n$report1s"
	for report1 in $report1s
	do
		echo "report1: $report1"
		filename=$(basename $report1)
		# Extract sample information from the filename
		identifier=$(echo $filename | perl -pe 's/^(.*)_R1.*/\1/')
		sample=$(echo $filename | perl -pe 's/^([CM]{1}[[:digit:]]{1,2}).*/\1/')
		#echo "sample: $sample"
		treatment=$(echo $filename | awk '{
			if ($0 ~ /_NOT_BS_/){t="NOT BS"}
			else{t="BS"}
			print t}' )
		echo "treatment: $treatment"
		infection=$(echo $f2 | awk '{
			if ($0 ~ /^C/){i="Control"}
			else{i="M. bovis"}
			print i}' )
#		echo "infection: $infection"
		lane=$(echo $filename | perl -pe 's/.*(L[[:digit:]]{3}).*/\1/')
#		echo "lane: $lane"
		# Extract information for the forward read
		info_forward=$(extract_info $report1)
		
		echo "\"$batch\",\"$identifier\",\"$filename\",\"$sample\",\"$treatment\",\"$infection\",\"$lane\",\"$info_forward\""
		exit
	done
done
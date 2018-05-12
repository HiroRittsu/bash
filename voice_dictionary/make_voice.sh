#!/bin/bash

if [ -z $1 ]; then
	echo "ファイル名を指定してください。"
	exit 1
fi

YOMI="$1.yomi"
CSV="$1.csv"

rm $YOMI
rm $CSV

touch $YOMI
touch $CSV

sed -i "s/\t/_/g" tabtest.tsv

cat tabtest.tsv | while read LINE
do
	#yomi
	out1=`echo $LINE | awk ' BEGIN { FS = "_" } { print $1 }'`
	out1=`echo $out1 | sed "s/What's /What is /g" | sed "s/I'm /I am /g" | sed "s/n't / not /g" | sed "s/I’d /I would /g" | sed "s/’ve / have /g" | sed "s/’re / are /g"`
	out1=`echo $out1 | sed "s/?//g" | sed "s/!//g" | sed "s/ //g"`
	echo -n $out1 >> $YOMI
	echo -n -e '\t' >> $YOMI
	echo -n `echo $LINE | awk ' BEGIN { FS = "_" } { print $2 }'` >> $YOMI
	echo -n -e '\n' >> $YOMI

	#csv
	out2=`echo $LINE | awk ' BEGIN { FS = "_" } { print $3 }'`
	out2=`echo $out2 | sed "s/What's /What is /g" | sed "s/I'm /I am /g" | sed "s/n't / not /g" | sed "s/I’d /I would /g" | sed "s/’ve / have /g" | sed "s/’re / are /g"`
	echo -n $out1 >> $CSV
	echo -n ";" >> $CSV
	echo -n $out2 >> $CSV
	echo -n -e '\n' >> $CSV

done

sed -i "s/_/\t/g" tabtest.tsv

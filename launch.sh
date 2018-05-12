#!/bin/sh

LOG=make.log

trap 'last' {1,2,3,15}

last() {

	for a in ${killlist[@]}
	do

	
		kill `ps aux | grep "$a" | grep -v "gnome-terminal" | awk '{print $2}'` &>/dev/null


	done

	exit 1
}
clear

echo
echo "##############コンパイル中#############"
echo

if [ -z $1 ] || [ $1 -ne 0 ]; then

	catkin_make 2> $LOG

fi

if [ -f $LOG ] && [ `cat "$LOG" | grep -c "エラー"` -ne 0 ]; then

	clear
	echo
	echo "##############コンパイルエラー#############"
	echo

	tail=`grep -e "個" -n $LOG | sed -e 's/:.*//g' | awk '{if (max<$1) max=$1} END {print max}'`

	if [ -z $tail ]; then

		cat $LOG

	else

		head -"$tail" $LOG

	fi

	echo
	exit 1

fi

clear
echo

list=(`find ./ -name "*.java" | grep -v "open"`) #OpenCVライブラリを除外

if [ ${#list[*]} -eq 0 ]; then

	echo "ソースコードが見つかりません。"
	exit 1

fi

if [ $# -eq 0 ] || [ $1 -eq 0 ]; then

	line=0

	echo
	echo "##############ノードの選択#############"
	echo

	for a in ${list[@]}
	do
		line=$(($line+1))
		package=`echo $a | sed 's@/@ @g' | awk '{print $3}'`
		projct=`echo $a | sed 's@/@ @g' | awk '{print $4}'`
		src=`echo $a | sed 's@/@ @g' | awk '{print $NF}'`

		printf "%3d : %s	%s/%s\n" $line $src $package $projct 
	

	done

	while true
	do

		read input

		input=$(($input-1))
	
		if [[ "$input" =~ ^[0-9]+$ ]]; then
	  		numberlist=(${numberlist[@]} $input)
		else
	  		break #文字が入力されたら
		fi

	done

else

	for i in $@
	do
		i=$(($i-1))
		numberlist=(${numberlist[@]} $i)	

	done

fi



if [ `ps aux | grep "roscore" | grep -v -c "grep"` -eq 0 ]; then #roscoreが立ち上がっていない場合

	gnome-terminal -x  bash -c "

		roscore

	" &

	sleep 10
fi

for i in ${numberlist[@]}
do

	exe=`echo ${list["$i"]}`
	package=`echo $exe | sed 's@/@ @g' | awk '{print $3}'`
	projct=`echo $exe | sed 's@/@ @g' | awk '{print $4}'`
	src=`echo $exe | sed 's@/@ @g' | awk '{print $NF}'`

	cd ~/Ros/java/src/"$package"/"$projct"/build/install/"$projct"/bin/

	gnome-terminal -x  bash -c "

		echo "$package/$projct/$src"

		./"$projct" `echo $src | sed 's/.java//g'`

	" &

	killlist=(${killlist[@]} `echo $src | sed 's/.java//g'`)

done

while true
do

	sleep 1

done





#!/bin/sh

LOG=make.log
CATKIN_LANG=""

trap 'last' {1,2,3,15}

last() {

	for a in ${killlist[@]}
	do

		kill `ps aux | grep "$a" | grep -v "gnome-terminal" | awk '{print $2}'` &>/dev/null

	done

	kill `ps aux | grep "freenect_launch" | grep -v "gnome-terminal" | awk '{print $2}'` &>/dev/null
	kill `ps aux | grep "joy" | grep -v "gnome-terminal" | awk '{print $2}'` &>/dev/null
	kill `ps aux | grep "bringup" | grep -v "gnome-terminal" | awk '{print $2}'` &>/dev/null

	exit 1
}

clear

if [ `find ./ | grep -c "gradle"` -eq 0 ]; then

	CATKIN_LANG="cpp"
	
	#CMakeListの設定
	cd ./src

	for i in `find ./ -name *.cpp`; do

		cd `echo $i | sed 's@/@ @g' | awk '{print $2}'` #パッケージ内に移動
		
		TARGET=`echo $i | sed 's@/@ @g' | awk '{print $4}' | sed 's/.cpp//g'`
		 
		if [ `cat CMakeLists.txt | grep -c $TARGET` -lt 2 ]; then
		
			echo "add_executable($TARGET src/$TARGET.cpp)" >> CMakeLists.txt
			echo "target_link_libraries($TARGET" ' ${catkin_LIBRARIES})' >> CMakeLists.txt
		
		fi
		cd ../
	
	done
	
	cd ../
	source devel/setup.bash		

else

	CATKIN_LANG="java"

fi

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

[ $CATKIN_LANG = 'cpp' ] && list=(`find ./ -name "*.cpp" | grep -v "CMake"`)

[ $CATKIN_LANG = 'java' ] && list=(`find ./ -name "*.java" | grep -v "open"`) #OpenCVライブラリを除外

if [ ${#list[*]} -eq 0 ]; then

	echo "ソースコードが見つかりません。"
	exit 1
	
fi

if [ $# -eq 0 ] || [ $1 -eq 0 ]; then

	line=0

	echo
	echo "##############ノードの選択#############"
	echo
	echo "●　選択終了の際は0を入力してください"

	line=$(($line+1))
	printf "%3d : gazebo-kobuki\n" $line #kobuki-gazebo起動
	line=$(($line+1))
	printf "%3d : gazebo-turtlebot\n" $line #turtlebot-gazebo起動
	line=$(($line+1))
	printf "%3d : kinect\n" $line #コントローラー
	line=$(($line+1))
	printf "%3d : joy\n" $line #キネクト
	line=$(($line+1))
	printf "%3d : bringup\n" $line #bringup起動
	echo "-------------------------------------"

	for a in ${list[@]}
	do
		line=$(($line+1))
		package=`echo $a | sed 's@/@ @g' | awk '{print $3}'`
		projct=`echo $a | sed 's@/@ @g' | awk '{print $4}'`
		src=`echo $a | sed 's@/@ @g' | awk '{print $NF}'`

		printf "%3d : %s		%s/%s\n" $line $src $package $projct 

	done
	
	while true
	do

		read input
	
		if [[ "$input" =~ ^[0-9]+$ ]]; then
		
			input=$(($input-1))

			[ $input -eq -1 ] && break

			if [ $line -le $input ]; then
		
				echo "　　1から$line以下の数字を選んでください"
				continue

			fi
		
	  		numberlist=(${numberlist[@]} $input)
		else
			echo "　　数字を入力してください"
		fi

	done

else

	for i in $@
	do
		i=$(($i-1))
		numberlist=(${numberlist[@]} $i)	

	done

fi

[ ${#numberlist[@]} -eq 0 ] && exit 1

if [ `ps aux | grep "roscore" | grep -v -c "grep"` -eq 0 ] && [ `ps aux | grep "roslaunch" | grep -v -c "grep"` -eq 0 ]; then #roscoreが立ち上がっていない場合

	gnome-terminal -x  bash -c "

		roscore

	" &

	sleep 5
fi



for i in ${numberlist[@]}
do

	if [ $i -eq 0 ]; then

		gnome-terminal -x  bash -c "

			echo 'kobuki_gazebo'
			roslaunch kobuki_gazebo kobuki_playground.launch

		" &	

		sleep 5
		continue

	fi

	if [ $i -eq 1 ]; then

		gnome-terminal -x  bash -c "

			echo 'turtlebot_gazebo'
			roslaunch turtlebot_gazebo turtlebot_world.launch

		" &	

		sleep 5
		continue

	fi

	if [ $i -eq 2 ]; then

		if [ `ps aux | grep "freenect_launch" | grep -v -c "grep"` -eq 0 ]; then #kinect freenectが立ち上がっていない場合

			gnome-terminal -x  bash -c "

				echo 'freenect_launch'
				roslaunch freenect_launch freenect.launch

			" &

			sleep 5
		fi
		continue

	fi

	if [ $i -eq 3 ]; then

		if [ `ps aux | grep "ds4" | grep -v -c "grep"` -eq 0 ]; then #ds4rvが立ち上がっていない場合
			
			touch log
		
			gnome-terminal -x  bash -c "

				sudo ds4drv | tee log		

			" &

			while true
			do

				if [ `cat log | grep -c 'Signal strength'` -eq 1 ]; then

					rm log
					break

				fi

			done

			sleep 1

		fi

		gnome-terminal -x  bash -c "

			rosrun joy joy_node

		" &
		continue

	fi

	if [ $i -eq 4 ]; then	

		gnome-terminal -x  bash -c "

			echo 'turtlebot_bringup'
			roslaunch turtlebot_bringup minimal.launch

		" &
		continue

	fi


	exe=`echo ${list["$((i-5))"]}`
	package=`echo $exe | sed 's@/@ @g' | awk '{print $3}'`
	projct=`echo $exe | sed 's@/@ @g' | awk '{print $4}'`
	src=`echo $exe | sed 's@/@ @g' | awk '{print $NF}'`
	
	if [ $CATKIN_LANG = 'cpp' ]; then
		
		gnome-terminal -x bash -c "

			echo "$package/$src"

			rosrun $package `echo $src | sed 's/.cpp//g'`

		" &

		killlist=(${killlist[@]} `echo $src | sed 's/.cpp//g'`)
	
	else

		cd ~/Ros/java/src/"$package"/"$projct"/build/install/"$projct"/bin/

		gnome-terminal -x  bash -c "

			echo "$package/$projct/$src"

			./"$projct" `echo $src | sed 's/.java//g'`

		" &

		killlist=(${killlist[@]} `echo $src | sed 's/.java//g'`)
	
	fi

done

while true
do

	sleep 1

done

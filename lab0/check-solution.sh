#/bin/bash

# note that the answer files in railwayplanning are different from EDAF05!

for x in ../data/tiny/*.in ../data/railwayplanning/*/*.in
do
	echo $x
	pre=${x%.in}
	ans=$pre.ans
	start=$(date +%s%N)
        $* < $x | grep '^f = ' | sed 's/f = //' > out
	end=$(date +%s%N)
	echo "time: $(( (end - start) / 1000000 )) ms"
	if diff $ans out
	then
		echo PASS $x 
		rm out
	else
		echo FAIL $x
		exit 1
	fi
done

for y in big huge
do
	for x in ../data/$y/*.in
	do
		echo $x
		pre=${x%.in}
		ans=$pre.ans
		start=$(date +%s%N)
		$* < $x | grep '^f = ' | sed 's/f = //' > out
		end=$(date +%s%N)
		echo "time: $(( (end - start) / 1000000 )) ms"
		if diff $ans out
		then
			echo PASS $x 
			rm out
		else
			echo FAIL $x
			exit 1
		fi
	done
done

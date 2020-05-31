#!/usr/bin/env bash


for side in src tgt; do
    printf "#### Side:$side ###\n"
    header_flag=
    for suit in runs-*; do
	for exp in $suit/0*-r1 ; do 
	    stat=$exp/stats.train.$side.txt
	    if [[ ! -s $stat ]]; then
		printf "$exp\tNA\n" 
		continue
	    fi

	    if [[ -z $header_flag ]]; then # header
		printf "Experiment\t"
		head -2 $stat | sed 's/# [^ ]* //' | tr '\n' ' ' | awkg  'R=R[0::2]; RET=1' | tr ' ' '\t'
		header_flag="done"
	    fi
	    printf "$exp\t"
	    head -2 $stat | sed 's/# [^ ]* //' | tr '\n' ' ' | awkg  'R=R[1::2]; RET=1' | tr ' ' '\t'
	done
	printf "\n"
    done
    printf "\n"
done

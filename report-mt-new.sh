#!/usr/bin/env bash

set -euo pipefail

# pip install sacrebleu-macrof   # for macrof1 support
# <script.sh> exp1 exp2 exp3 ...

[[ $# -eq 0 ]] && {
    echo "Usage:: $ ./report-mt.sh <exp1> <exp2> <exp3>"
    echo "   <exp1> ... positional args are path to experiment dirs"
    exit 1
}


function sacre_bleu {
    hyp=$1
    ref=$2
    if [[ ! -f $hyp ]]; then
        echo "NA-Hyp"
    elif [[ ! -f $ref ]]; then
        echo "NA-Ref"
    else
	echo $(cut -f1 $hyp | sed 's/<unk>//g' | python -m sacrebleu -m bleu -b $ref)
    fi
}


function macro_f1 {
    hyp=$1
    ref=$2
    if [[ ! -f $hyp ]]; then
        echo "NA-Hyp"
    elif [[ ! -f $ref ]]; then 
        echo "NA-Ref"
    else
	echo $(cut -f1 $hyp | sed 's/<unk>//g' | python -m sacrebleu -m macrof -b $ref)
    fi

}

function detokenize {
    lang=$1
    if [[ $lang == 'hin' ]]; then
	python -m indicnlp.tokenize.indic_detokenize
    elif [[ $lang == 'lit' ]]; then
	sacremoses -l lt detokenize
    elif [[ $lang == 'deu' ]]; then
	sacremoses -l de detokenize
    else
	sacremoses detokenize
    fi	
}

echo "Reporting BLEU and MacroF1 "
delim=${delim:-','}
#delim='\t'

# extract test names automatically
names=$(for i in ${@}; do
	    [[ -d $(echo $i/test_*) ]] || continue
	    for j in ${i}/test_*/*.ref ; do
		basename $j; done
	done | sed 's/.ref$//' | sort | uniq )

names_str=$(echo $names | sed "s/ /$delim/g")
printf "Experiment${delim}BLEU: ${names_str}MacroF1: ${names_str}\n"
for d in ${@}; do
    for td in $d/test_*; do
	for t in $names; do
	    hyp=${td}/$t.out.tsv
	    hyp_detok=${td}/$t.out.detok
	    ref=${td}/$t.ref
	    [[ -f $ref ]] || continue
	    if [[ -f $hyp && ! -f $hyp_detok ]]; then
		p=$(readlink $ref)
		ext=${p##*.}    #  longest match from beginning until .
		cut -f1 $hyp | detokenize $ext > $hyp_detok.tmp && mv $hyp_detok.tmp $hyp_detok
	    fi
	done
	printf "$td"
	for t in $names; do
            hyp_detok=${td}/$t.out.detok
            ref=${td}/$t.ref
            score=$(sacre_bleu $hyp_detok $ref)
            printf "${delim}${score}"
	done
	for t in $names; do
            hyp_detok=${td}/$t.out.detok
            ref=${td}/$t.ref
            score=$(macro_f1 $hyp_detok $ref)
            printf "${delim}${score}"
	done
	printf "\n"
    done
done

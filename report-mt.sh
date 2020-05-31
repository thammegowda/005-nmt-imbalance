#!/usr/bin/env bash

# with macroBLEU and macroF1 support
export PYTHONPATH=/home/07394/tgowda/repos/sacre-BLEU
##
#MEASURE=BLEU <script.sh> exp1 exp2 exp3 ...

[[ $# -eq 0 ]] && {
    echo "Usage:: $ MEASURE=<name> ./report-mt.sh <exp1> <exp2> <exp3>"
    echo "   MEASURE variable can be set to one of BLEU (default), MacroBLEU, MacroF1"
    echo "   <exp1> ... positional args are path to experiment dirs"
    exit 1
}


MEASURE=${MEASURE:-BLEU}


function sacre_bleu {
    hyp=$1
    ref=$2
    if [[ -f $ref && -f $hyp ]]; then
        # ;s/<pad>//g
        score=$(cut -f1 $hyp | sed 's/<unk>//g' | python -m sacrebleu -m bleu -b $ref)
        echo $score
    else
        if [[ ! -f $hyp ]]; then
            echo "NA-Hyp"
        else
            echo "NA-Ref"
        fi
    fi
}

function macro_bleu {
    hyp=$1
    ref=$2
    if [[ -f $ref && -f $hyp ]]; then
        # ;s/<pad>//g
        score=$(cut -f1 $hyp | sed 's/<unk>//g' | python -m sacrebleu -m rebleu -ro 4 -w 2 -a macro -b  $ref)
        echo $score
    else
        if [[ ! -f $hyp ]]; then
            echo "NA-Hyp"
        else
            echo "NA-Ref"
        fi
    fi
}
function macro_f1 {
    hyp=$1
    ref=$2
    if [[ -f $ref && -f $hyp ]]; then
        # ;s/<pad>//g
        score=$(cut -f1 $hyp | sed 's/<unk>//g' | python -m sacrebleu -m rebleu -ro 1 -w 2 -a macro -b  $ref)
        echo $score
    else
        if [[ ! -f $hyp ]]; then
            echo "NA-Hyp"
        else
            echo "NA-Ref"
        fi
    fi
}

if [[ $MEASURE == 'BLEU' ]]; then 
    scorer=sacre_bleu
elif [[ $MEASURE == 'MacroBLEU' ]]; then 
    scorer=macro_bleu
elif [[ $MEASURE == 'MacroF1' ]]; then 
    scorer=macro_f1
else
    echo "ERROR: $MEASURE is not known; what I know: BLEU, MacroBLEU, MacroF1; export MEASURE=<name>"
    echo "Usage"
    exit 1   
fi

echo "Reporting $MEASURE $scorer"

delim=${delim:-','}
#delim='\t'

# extract test names automatically
names=$(for i in ${@}; do [[ -d $(echo $i/test_*) ]] || continue; for j in ${i}/test_*/*.ref ; do basename $j; done done | sed 's/.ref$//' | sort | uniq)
names_str=$(echo $names | sed "s/ /$delim/g")
printf "Experiment/$MEASURE${delim}${names_str}\n"
for d in ${@}; do
    for td in $d/test_*; do
    printf "$td"
        for t in $names; do
            hyp_detok=${td}/$t.out.detok
            ref=${td}/$t.ref
            score=$($scorer $hyp_detok $ref)
            printf "${delim}${score}"
        done
        printf "\n"
    done
    #printf "\n"
done

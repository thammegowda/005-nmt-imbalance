#!/usr/bin/env bash

export PYTHONPATH=/home/07394/tgowda/repos/sacre-BLEU

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
        score=$(cut -f1 $hyp | sed 's/<unk>//g' | python -m sacrebleu --force -m rebleu -ro 4 -w 2 -a macro -b  $ref)
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
        score=$(cut -f1 $hyp | sed 's/<unk>//g' | python -m sacrebleu --force -m rebleu -ro 1 -w 2 -a macro -b  $ref)
        echo $score
    else
        if [[ ! -f $hyp ]]; then
            echo "NA-Hyp"
        else
            echo "NA-Ref"
        fi
    fi
}

delim=','

names=$(for i in ${@}; do [[ -d $(echo $i/test_*) ]] || continue; for j in ${i}/test_*/*.ref ; do basename $j; done done | sed 's/.ref$//' | sort | uniq)
names_str=$(echo $names | sed "s/ /$delim/g")
#printf "Experiment${delim}${names_str}${delim}MacroF1:${names_str}\n"
printf "Experiment${delim}${names_str}\n"
for d in ${@}; do
    for td in $d/test_*; do
    printf "$td"
        for t in $names; do
            hyp_detok=${td}/$t.out.detok
            ref=${td}/$t.ref
            bleu=$(sacre_bleu $hyp_detok $ref)
            printf "${delim}${bleu}"
        done
        # macro F1
        #for t in $names; do
        #    hyp_detok=${td}/$t.out.detok
        #    ref=${td}/$t.ref
        #    score=$(macro_f1 $hyp_detok $ref)
        #    printf "${delim}${score}"
        #done
        printf "\n"
    done
    #printf "\n"
done

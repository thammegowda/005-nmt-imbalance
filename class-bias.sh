#!/usr/bin/env bash

# this script finds class bias of an NMT model
x_dir=$(echo $1 | sed 's:/$::')
model=$x_dir/data/nlcodec.tgt.model
[[ -d $x_dir ]] || { echo "Experiment dir $x_dir not found";  exit 1; }
[[ -f $model ]] || { echo "model $model not found"; exit 2; }

N_CPU=10
n_gram=1
echo NSLOTS=$N_CPU
export NLCODEC_THREADS=$N_CPU  # 

terms_file=$x_dir/data/train.termfreq.${n_gram}grams.stats

if [[ ! -s $terms_file ]]; then
    echo "creating terms file: $terms_file"
    train_tgt=$(dirname $x_dir)/$(grep 'train_tgt' $x_dir/conf.yml  | grep -o '[^ ]*$')
    [[ -f $train_tgt ]] || { echo "Cant find train_tgt $train_tgt"; exit 3; }
    python -m nlcodec.eval.termfreq -i $train_tgt -o $terms_file -m $model -n $n_gram
fi
out_dir=analysis/prec_recall/$(echo $x_dir | sed 's/\/$//' | awk -F '/' '{print $(NF-1)"/"$NF}')
echo "$x_dir -> $out_dir" 
[[ -d $out_dir ]] || mkdir -p $out_dir

for cand in $x_dir/test_*/*.out.tsv; do 
    ref=${cand/.out.tsv/.ref}
    ref_tok=$(realpath $ref).tok
    [[ -f $cand ]] || { echo "cand NOT found: $cand"; exit 4; }
    [[ -f $ref_tok ]] || { echo "ref tok NOT found: $ref_tok"; exit 5; }
    cand_name=$(basename $cand)
    out=$out_dir/${cand_name/.out.tsv/}.${n_gram}gram.pr.tsv
    python -m nlcodec.eval.pr_measure -c <(cut -f1 $cand) -r $ref_tok -f $terms_file -o $out -m $model -n $n_gram
done

echo "Done" 

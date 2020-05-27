#!/usr/bin/env bash

#SBATCH --partition=v100
#SBATCH --mem=64G
#SBATCH --time=0-10:00:00
#SBATCH --nodes=1 --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --gres=gpu:0
#SBATCH --output=R-%x.out.%j
#SBATCH --error=R-%x.err.%j
#SBATCH --export=NONE


set -e

source ~/.bashrc
#conda deactivate
#conda activate fairseq

ROOT=~/work/papers/nmt-imbalance/rtg-runs/
DATA=$ROOT/data

log() { printf "$(date --rfc-3339 s): $1\n"; }
exit_log() { log "$2";  exit $1; }

N_CPU=20

# check requirements
# pip install nlcodec mtdata  mtdata==0.2.3
for lib in nlcodec mtdata sacremoses awkg; do
    which $lib > /dev/null || exit_log 1 "$lib required but not found"
done
 python -m indicnlp.tokenize.indic_tokenize <(echo test) /dev/null hi || exit_log 1 'pip install indic-nlp-library' 


clean_parallel() {

awkg -F '\t' -b 'from html import unescape; goods, bads = 0, 0' '
good = len(R) == 2
if good:
  src = R[0].strip()
  tgt = R[1].strip()
  good = good and "http" not in src and "http" not in tgt
  src = unescape(src).split()
  tgt = unescape(tgt).split()
  good = good and 1 <= len(src) <= 512 and 1 <= len(tgt) <= 512
  good = good and 1/5 <= len(src)/len(tgt) <= 5
  good = good and max(len(w) for w in src + tgt) < 30

if good:
   goods += 1
   print(" ".join(src), " ".join(tgt))
else:
   bads += 1

# if not good: # print bad
#  print(R0)
' -e 'sys.stderr.write(f"good={goods:,} bad={bads:,} records")'

}

deen=$DATA/deu-eng
# Step download mtdata
[[ -f $deen/_DOWNd ]] && log "Skip deu-eng; rm $deen/_DOWNd to force" || {
    [[ -f $deen/mtdata.signature.txt ]] \
	|| mtdata get -l deu-eng \
	-tr europarl_v9 wmt13_commoncrawl news_commentary_v14 \
	-ts newstest2018_ende newstest2019_ende newstest2014_deen \
	-o $deen --merge \
	|| exit_log $1 "download failed"

    # remove deu_eng from test names; to simplify
    for i in $deen/tests/*-deu_eng*; do 
	[[ -f $i ]] && mv $i ${i/-deu_eng/}
    done
    # move these as orig, make place for cleaned
    [[ -f $deen/train.eng ]] && mv $deen/train.eng{,.orig}
    [[ -f $deen/train.deu ]] && mv $deen/train.deu{,.orig}

    printf "de deu\nen eng\n" | while read iso2 lang; do
	for f in $deen/train.$lang.orig $deen/tests/*.$lang; do
	    [[ -f $f.tok  && "$(wc -l < $f)" -eq "$(wc -l < $f.tok)" ]] && continue
	    log "tokenize: $f -> $f.tok"
	    sacremoses -l $iso2 -j $N_CPU tokenize -x < $f > $f.tok || exit_log 1 "tokenization fail"
	done
    done

    [[ -f $deen/train.deu-eng.cln.tok ]] || paste $deen/train.{deu,eng}.orig.tok | clean_parallel  > $deen/train.deu-eng.cln.tok
    cut -f1 $deen/train.deu-eng.cln.tok > $deen/train.all.deu.tok
    cut -f2 $deen/train.deu-eng.cln.tok > $deen/train.all.eng.tok


    log "shuffling and preparing subsets"
    cat $deen/train.deu-eng.cln.tok | shuf --random-source=$deen/train.eng.orig > $deen/train-shuf.all.deu-eng.tok

    printf "030k 30000\n500k 500000\n001m 1000000\n" | while read name size; do
	cut -f1 $deen/train-shuf.all.deu-eng.tok | head -$size > $deen/train.$name.deu.tok
	cut -f2 $deen/train-shuf.all.deu-eng.tok | head -$size > $deen/train.$name.eng.tok
    done
 
    touch $deen/_DOWNd 
}


hien=$DATA/hin-eng

[[ -f $hien/_DOWNd ]] && log "Skip hin-eng; rm $hien/_DOWNd to force" || {
    [[ -f $hien/mtdata.signature.txt ]] \
	|| mtdata get -l hin-eng \
	-tr IITBv1_5_train \
	-ts IITBv1_5_dev IITBv1_5_test \
	-o $hien --merge \
	|| exit_log $1 "hin-eng download failed"

    # remove hin_eng from test names; to simplify
    for i in $hien/tests/*-hin_eng*; do 
	[[ -f $i ]] && mv $i ${i/-hin_eng/}
    done
    # move these as orig, make place for cleaned
    [[ -f $hien/train.eng ]] && mv $hien/train.eng{,.orig}
    [[ -f $hien/train.hin ]] && mv $hien/train.hin{,.orig}
    
    # ennglish using sacremoses, -x is for dont escape XML chars
    for f in $hien/train.eng.orig $hien/tests/*.eng; do
	[[ -f $f.tok  && "$(wc -l < $f)" -eq "$(wc -l < $f.tok)" ]] && continue
	log "tokenize: $f -> $f.tok"
	sacremoses -l en -j $N_CPU tokenize -x < $f > $f.tok || exit_log 1 "tokenization fail"
    done
    
    for f in $hien/train.hin.orig $hien/tests/*.hin; do
	[[ -f $f.tok  && "$(wc -l < $f)" -eq "$(wc -l < $f.tok)" ]] && continue
	log "tokenize: $f -> $f.tok"
	python -m indicnlp.tokenize.indic_tokenize $f $f.tok hi || exit_log 1 "tokenization fail"
    done


    [[ -f $hien/_CLNd ]] || {
	log "Clearning and deduping "
	paste $hien/train.{hin,eng}.orig.tok | clean_parallel  | sort | uniq > $hien/train.hin-eng.cln.tok
	cut -f1 $hien/train.hin-eng.cln.tok > $hien/train.all.hin.tok
	cut -f2 $hien/train.hin-eng.cln.tok > $hien/train.all.eng.tok
	touch $hien/_CLNd
    }


    log "shuffling and preparing subsets"
    cat $hien/train.hin-eng.cln.tok | shuf --random-source=$hien/train.eng.orig > $hien/train-shuf.all.hin-eng.tok

    printf "030k 30000\n500k 500000\n001m 1000000\n" | while read name size; do
	cut -f1 $hien/train-shuf.all.hin-eng.tok | head -$size > $hien/train.$name.hin.tok
	cut -f2 $hien/train-shuf.all.hin-eng.tok | head -$size > $hien/train.$name.eng.tok
    done
 
    touch $hien/_DOWNd 
}

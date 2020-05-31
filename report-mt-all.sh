#!/usr/bin/env bash

# reports all MT scores
#for mn in BLEU MacroBLEU MacroF1; do
for mn in BLEU; do
#for mn in MacroF1; do
    export delim='\t'
    MEASURE=$mn ./report-mt.sh runs-{ende,deen}-*/0*  > $mn-report.tsv
    MEASURE=$mn ./report-mt.sh runs-enhi-*/0*  >> $mn-report.tsv
done

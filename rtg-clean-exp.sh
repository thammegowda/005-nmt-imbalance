#!/usr/bin/env bash 
exp=$1
exit_log() {
    echo "$2"
    exit $1
}

[[ -n $exp && -d $exp ]] || exit_log 1 "<arg1> require and shouldbe a dir"


for i in rtg.zip rtg.log tensorboard models _TRAINED; do
    [[ -d $exp/$i || -f $exp/$i ]] && rm -rf  $exp/$i
done
test_dirs=$(echo $exp/test_*)
for td in $test_dirs; do
    [[ -d $td ]] && rm -rf  $td
done


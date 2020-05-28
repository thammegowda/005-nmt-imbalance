#!/usr/bin/env bash

#SBATCH --partition=v100
#SBATCH --mem=6g
#SBATCH --time=6:00:00
#SBATCH --nodes=1 --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --gres=gpu:v100:0
#SBATCH --output=R-%x.out.%j
#SBATCH --error=R-%x.err.%j
#SBATCH --export=NONE

# A script to extract "some useful" stats from training data 
# that help in deciding optimal BPE operations
#
# Author = Thamme Gowda (tg@isi.edu)
# Date =  May 26, 2020

#SCRIPTS_DIR=$(dirname "${BASH_SOURCE[0]}")  # get the directory name
#RTG_PATH=$(realpath "${SCRIPTS_DIR}/..")

# If using compute grid, and dont rely on this relative path resolution, set the RTG_PATH here
RTG_PATH=~tgowda/repos/rtg


#CONDA_ENV=rtg     # empty means don't activate environment
CONDA_ENV=
source ~/.bashrc

echo "Experiment dir = $XDIR"
if [[ -n ${CONDA_ENV} ]]; then
    echo "Activating environment $CONDA_ENV"
    source activate ${CONDA_ENV} || { echo "Unable to activate $CONDA_ENV" ; exit 3; }
fi

#export PYTHONPATH=$XDIR/rtg.zip
export PYTHONPATH=$RTG_PATH  # use latest code , 

for XDIR in "$@"; do
    echo $XDIR
    # dont use GPUs even if they exist
    CUDA_VISIBLE_DEVICES= python -m rtg.eval.datastat $XDIR src -o $XDIR/stats.train.src.txt
    CUDA_VISIBLE_DEVICES= python -m rtg.eval.datastat $XDIR tgt -o $XDIR/stats.train.tgt.txt
done


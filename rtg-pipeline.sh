#!/usr/bin/env bash


#SBATCH --partition=v100
### SBATCH --mem=90g
#SBATCH --time=1-12:00:00
#SBATCH --nodes=1 --ntasks=1
#SBATCH --cpus-per-task=40
#SBATCH --gres=gpu:v100:4
#SBATCH --output=R-%x.out.%j
#SBATCH --error=R-%x.err.%j
#SBATCH --export=NONE

# Pipeline script for MT
#
# Author = Thamme Gowda (tg@isi.edu)
# Date = April 3, 2019

#SCRIPTS_DIR=$(dirname "${BASH_SOURCE[0]}")  # get the directory name
#RTG_PATH=$(realpath "${SCRIPTS_DIR}/..")


# If using compute grid, and dont rely on this relative path resolution, set the RTG_PATH here
#RTG_PATH=/full/path/to/rtg-master
RTG_PATH=~tgowda/repos/rtg
#RTG_PATH=/nas/material/users/tg/work/projects/nmt-multilabel/rtg-175-multilabel

# Use tmp dir
#export RTG_TMP=$TMPDIR
export RTG_TMP=$SCRATCH/tmp
# restrict threads / cpus

export RTG_CPUS=120     #$SLURM_CPUS_ON_NODE
export OMP_NUM_THREADS=$RTG_CPUS
export MKL_NUM_THREADS=$RTG_CPUS

OUT=
CONF_PATH=

#defaults
#CONDA_ENV=rtg     # empty means don't activate environment
CONDA_ENV=
source ~/.bashrc

usage() {
    echo "Usage: $0 -d <exp/dir>
    [-c conf.yml (default: <exp/dir>/conf.yml) ]
    [-e conda_env  default:$CONDA_ENV (empty string disables activation)] " 1>&2;
    exit 1;
}

while getopts ":fd:c:e:p:" o; do
    case "${o}" in
        d) OUT=${OPTARG} ;;
        c) CONF_PATH=${OPTARG} ;;
        e) CONDA_ENV=${OPTARG} ;;
        *) usage ;;
    esac
done


[[ -n $OUT ]] || usage   # show usage and exit

#################
#NUM_GPUS=$(echo ${CUDA_VISIBLE_DEVICES} | tr ',' '\n' | wc -l)

echo "Output dir = $OUT"
[[ -d $OUT ]] || mkdir -p $OUT
OUT=`realpath $OUT`

if [[ ! -f $OUT/rtg.zip ]]; then
    [[ -f $RTG_PATH/rtg/__init__.py ]] || { echo "Error: RTG_PATH=$RTG_PATH is not valid"; exit 2; }
    echo "Zipping source code to $OUT/rtg.zip"
    OLD_DIR=$PWD
    cd ${RTG_PATH}
    zip -r $OUT/rtg.zip rtg -x "*__pycache__*"
    git rev-parse HEAD > $OUT/githead   # git commit message
    cd $OLD_DIR
fi

if [[ -n ${CONDA_ENV} ]]; then
    echo "Activating environment $CONDA_ENV"
    source activate ${CONDA_ENV} || { echo "Unable to activate $CONDA_ENV" ; exit 3; }
fi


export PYTHONPATH=$OUT/rtg.zip
# copy this script for reproducibility
cp "${BASH_SOURCE[0]}"  $OUT/job.sh.bak
echo  "`date`: Starting pipeline... $OUT"

CONF_ARG="$CONF_PATH"
if [[ -f $OUT/conf.yml && -n $CONF_PATH ]]; then
    echo "ignoring $CONF_PATH, because $OUT/conf.yml exists"
    CONF_ARG=""
fi

cmd="python -m rtg.pipeline $OUT $CONF_ARG --gpu-only"
echo "command::: $cmd"
if eval ${cmd}; then
    echo "`date` :: Done"
else
    echo "Error: exit status=$?"
fi

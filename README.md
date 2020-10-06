
# NMT Imbalance

This repository contains tools to reproduce the experiments reported in "Finding the optimal vocabulary for Neural Machine Translation" (**yet to appear at EMNLP 2020**)


# Tools :
- `pip install rtg==0.4.2` : https://pypi.org/project/rtg/#history   
- pip install indic-nlp-library nlcodec mtdata awkg sacremoses 


# Analysis
Available under `analysis` dir

# Get the datasets 

```bash
./get_data.sh
```

# Run experiments

Assumption: you have installed `rtg` via pip and `rtg-pipe` commnad or `python -m rtg.pipeline` is available.

Each directory that has `conf.yml` is an RTG experiment directory; you can rtg on it.
The only hiccup you need to resolve is make sure the paths in the config files are valid.
Since I had used symlinks with relative paths, those relative paths may break if you run from a different directory.

Please run each experiment from `runs-*` directory

You have two options. 
1. You can simply use `rtg-pipe` to one of those directories that have `conf.yml` file in them.  Example `rtg-pipe 
055-ende-08k08k-r1`

2. You may use rtg-pipeline.sh if you are submitting a job to slurm, e.g. `sbatch rtg-pipeline.sh -d 055-ende-08k08k-r1`. 
Please adapt `#SBATCH` to your cluster. 

### Recommendation:

1. cd to one of the run dirs; eg `cd runs-deen-all`
2. `for i in 0*; do sbatch -J $i rtg-pipeline.sh -d $i; done `



# Citation: 
TODO: get full citation fromm EMNLP
```
@misc{gowda2020nmt-vocab,
      title={Finding the Optimal Vocabulary Size for Neural Machine Translation}, 
      author={Thamme Gowda and Jonathan May},
      year={2020},
      eprint={2004.02334},
      archivePrefix={arXiv},
      primaryClass={cs.CL}
}
```



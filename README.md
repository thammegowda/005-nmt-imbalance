
# NMT Imbalance

This repository contains tools to reproduce the experiments reported in "Finding the optimal vocabulary for Neural Machine Translation" https://aclanthology.org/2020.findings-emnlp.352

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

https://aclanthology.org/2020.findings-emnlp.352

```
@inproceedings{gowda-may-2020-finding,
    title = "Finding the Optimal Vocabulary Size for Neural Machine Translation",
    author = "Gowda, Thamme  and
      May, Jonathan",
    booktitle = "Findings of the Association for Computational Linguistics: EMNLP 2020",
    month = nov,
    year = "2020",
    address = "Online",
    publisher = "Association for Computational Linguistics",
    url = "https://www.aclweb.org/anthology/2020.findings-emnlp.352",
    doi = "10.18653/v1/2020.findings-emnlp.352",
    pages = "3955--3964",
}

```



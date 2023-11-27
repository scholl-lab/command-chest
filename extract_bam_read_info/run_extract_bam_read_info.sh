#!/bin/bash

#SBATCH --job-name=gckd_read_info_job
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --time=168:00:00  # Adjust the time limit as needed
#SBATCH --mem-per-cpu=1200M  # Adjust memory requirements as needed
#SBATCH --output=slurm_logs/%x-%j.log

# Based on the best practices for temp files on Slurm clusters
# https://hpc-docs.cubi.bihealth.org/best-practice/temp-files/#tmpdir-and-the-scheduler
# https://bihealth.github.io/bih-cluster/slurm/snakemake/#custom-logging-directory

# First, point TMPDIR to the scratch in your home as mktemp will use this
export TMPDIR=$HOME/scratch/tmp
# Second, create another unique temporary directory within this directory
export TMPDIR=$(mktemp -d)
# Finally, setup the cleanup trap
trap "rm -rf $TMPDIR" EXIT

# Create a directory for Slurm logs if it doesn't exist
mkdir -p slurm_logs
# Set default options for Slurm jobs spawned by this script
export SBATCH_DEFAULTS=" --output=slurm_logs/%x-%j.log"

# Print the start date and time
date
# Run the Snakemake workflow
srun snakemake -s gckd_read_info.smk --use-conda --profile=cubi-v1 -j150
# Print the end date and time
date

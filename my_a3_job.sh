#!/bin/bash

# --- Slurm Directives ---
#SBATCH --job-name=my_simple_job  # Job name for identification
#SBATCH --partition=a3            # Specify the partition to run on
#SBATCH --nodes=1                 # Request 1 node
#SBATCH --ntasks-per-node=1       # Run 1 task per node
#SBATCH --gpus-per-node=8         # Request 8 GPUs on that node
#SBATCH --mem-per-gpu=80G         # Example: Request memory per GPU (adjust as needed)
#SBATCH --time=01:30:00           # Maximum job run time (1 hour, 30 minutes)
#SBATCH --output=job_output_%j.log # File for standard output (%j expands to job ID)
#SBATCH --error=job_error_%j.log   # File for standard error (%j expands to job ID)

# --- Job Commands ---
echo "Starting job $SLURM_JOB_ID on partition $SLURM_JOB_PARTITION"
echo "Running on node: $(hostname)"
echo "Allocated GPUs: $CUDA_VISIBLE_DEVICES" # Environment variable often set by Slurm

# Your actual commands go below
sleep 120       # Simulate some work
nvidia-smi      # Check GPU status
echo "Job finished."

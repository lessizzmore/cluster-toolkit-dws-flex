#!/bin/bash

# Slurm Job Directives
#------------------------------------
#SBATCH -J gpu_monitor_job      # Job name
#SBATCH -o slurm_gpu_%j.out     # Standard output file (%j expands to jobID)
#SBATCH -e slurm_gpu_%j.err     # Standard error file (%j expands to jobID)
#SBATCH -p gpu_partition        # Partition (queue) name - *Replace with your cluster's GPU partition*
#SBATCH -N 1                    # Number of nodes
#SBATCH --ntasks-per-node=1     # Number of tasks (processes) per node
#SBATCH --gres=gpu:1            # Request 1 GPU resource - *Syntax might vary (e.g., gpu:v100:1)*
#SBATCH -t 00:05:00             # Time limit D-HH:MM:SS (set to 5 minutes)
#------------------------------------

# Load necessary modules (if required by your cluster environment)
# module load cuda/toolkit # Example: uncomment and adjust if needed for nvidia-smi

echo "------------------------------------------------------------"
echo "SLURM JOB ID: $SLURM_JOB_ID"
echo "Running on host: $(hostname)"
echo "Requested GPU: $CUDA_VISIBLE_DEVICES" # Environment variable set by Slurm with --gres
echo "Job started at: $(date)"
echo "------------------------------------------------------------"

# Monitor GPU usage with nvidia-smi in a loop
# This loop will run nvidia-smi every 10 seconds for about 4.5 minutes (27 * 10 seconds = 270s)
echo "Starting nvidia-smi monitoring loop..."
for i in {1..27}; do
  echo "--- nvidia-smi output at iteration $i ---"
  nvidia-smi
  echo "-----------------------------------------"
  sleep 10
done

echo "------------------------------------------------------------"
echo "Monitoring loop finished."
echo "Job finished at: $(date)"
echo "------------------------------------------------------------"

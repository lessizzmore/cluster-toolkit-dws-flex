# create GCS bucket for tfstate
gcloud storage buckets create gs://ztan-hpc-sandbox-tfstate \
    --project=northam-ce-mlai-tpu \
    --default-storage-class=STANDARD --location=us-central1 \
    --uniform-bucket-level-access
gcloud storage buckets update gs://ztan-hpc-sandbox-tfstate --versioning


# create deployment folder from the cluster blueprint
./gcluster create hpc-gpu-dws-gcp-slurm-v6.yaml -l ERROR --vars project_id=northam-ce-mlai-tpu

# deploy HPC cluster using Terraform
./gcluster deploy ztan-hpc-gpu-dws

# Create Controller SA
gcloud iam service-accounts create controllernode \
  --project=northam-ce-mlai-tpu \
  --display-name="Slurm Controller Node SA"

# Create Compute SA
gcloud iam service-accounts create computenode \
  --project=northam-ce-mlai-tpu \
  --display-name="Slurm Compute Node SA"

# Create Login SA (likely needed too, even if no error yet)
gcloud iam service-accounts create loginnode \
  --project=northam-ce-mlai-tpu \
  --display-name="Slurm Login Node SA"

# Example roles for Controller SA (might need more)
gcloud projects add-iam-policy-binding northam-ce-mlai-tpu \
    --member="serviceAccount:controllernode@northam-ce-mlai-tpu.iam.gserviceaccount.com" \
    --role="roles/compute.instanceAdmin.v1"
gcloud projects add-iam-policy-binding northam-ce-mlai-tpu \
    --member="serviceAccount:controllernode@northam-ce-mlai-tpu.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser" # Allows acting as other SAs if needed
gcloud projects add-iam-policy-binding northam-ce-mlai-tpu \
    --member="serviceAccount:controllernode@northam-ce-mlai-tpu.iam.gserviceaccount.com" \
    --role="roles/logging.logWriter"
gcloud projects add-iam-policy-binding northam-ce-mlai-tpu \
    --member="serviceAccount:controllernode@northam-ce-mlai-tpu.iam.gserviceaccount.com" \
    --role="roles/monitoring.metricWriter"
gcloud projects add-iam-policy-binding northam-ce-mlai-tpu \
    --member="serviceAccount:controllernode@northam-ce-mlai-tpu.iam.gserviceaccount.com" \
    --role="roles/storage.objectAdmin" # For Slurm bucket state

# Example roles for Compute SA (adjust as needed)
gcloud projects add-iam-policy-binding northam-ce-mlai-tpu \
    --member="serviceAccount:computenode@northam-ce-mlai-tpu.iam.gserviceaccount.com" \
    --role="roles/compute.viewer" # Read compute resources
gcloud projects add-iam-policy-binding northam-ce-mlai-tpu \
    --member="serviceAccount:computenode@northam-ce-mlai-tpu.iam.gserviceaccount.com" \
    --role="roles/storage.objectAdmin" # Access scripts/data
gcloud projects add-iam-policy-binding northam-ce-mlai-tpu \
    --member="serviceAccount:computenode@northam-ce-mlai-tpu.iam.gserviceaccount.com" \
    --role="roles/logging.logWriter"
gcloud projects add-iam-policy-binding northam-ce-mlai-tpu \
    --member="serviceAccount:computenode@northam-ce-mlai-tpu.iam.gserviceaccount.com" \
    --role="roles/monitoring.metricWriter"

# Example roles for Login SA (adjust as needed)
gcloud projects add-iam-policy-binding northam-ce-mlai-tpu \
    --member="serviceAccount:loginnode@northam-ce-mlai-tpu.iam.gserviceaccount.com" \
    --role="roles/compute.viewer"
gcloud projects add-iam-policy-binding northam-ce-mlai-tpu \
    --member="serviceAccount:loginnode@northam-ce-mlai-tpu.iam.gserviceaccount.com" \
    --role="roles/storage.objectAdmin"
gcloud projects add-iam-policy-binding northam-ce-mlai-tpu \
    --member="serviceAccount:loginnode@northam-ce-mlai-tpu.iam.gserviceaccount.com" \
    --role="roles/logging.logWriter"
gcloud projects add-iam-policy-binding northam-ce-mlai-tpu \
    --member="serviceAccount:loginnode@northam-ce-mlai-tpu.iam.gserviceaccount.com" \
    --role="roles/monitoring.metricWriter"

set the default Google Cloud project for your gcloud command-line tool configuration is:
```
gcloud config set project northam-ce-mlai-tpu
```

create GCS bucket for tfstate
```
gcloud storage buckets create gs://ztan-hpc-sandbox-tfstate \
    --project=northam-ce-mlai-tpu \
    --default-storage-class=STANDARD --location=us-central1 \
    --uniform-bucket-level-access
gcloud storage buckets update gs://ztan-hpc-sandbox-tfstate --versioning
```

create VPC, subnet and firewall rules
```
# Set variables (optional, but makes commands easier to read/modify)
# Using the project ID from our previous discussion.
export PROJECT_ID="northam-ce-mlai-tpu"
export VPC_NAME="ztan-vpc-hpc"
export SUBNET_NAME="ztan-subnet-us-central1" # As per your original YAML intent
export SUBNET_REGION="us-central1"
export SUBNET_CIDR="10.128.0.0/20" # <-- Replace with your desired CIDR range if different

# Set the default project for gcloud commands
gcloud config set project $PROJECT_ID

# 1. Create the VPC network
#    --subnet-mode=custom is important so we can define subnets manually.
echo "Creating VPC network: $VPC_NAME..."
gcloud compute networks create $VPC_NAME \
    --project=$PROJECT_ID \
    --subnet-mode=custom \
    --mtu=1460 \
    --bgp-routing-mode=regional

# 2. Create the subnetwork
#    Replace --range with the specific IP CIDR block you want to use.
echo "Creating subnetwork: $SUBNET_NAME in region $SUBNET_REGION..."
gcloud compute networks subnets create $SUBNET_NAME \
    --project=$PROJECT_ID \
    --network=$VPC_NAME \
    --region=$SUBNET_REGION \
    --range=$SUBNET_CIDR

# 3. Create the internal traffic firewall rule
#    Allows all TCP, UDP, and ICMP traffic originating from within the subnet.
export FW_RULE_INTERNAL_NAME="${SUBNET_NAME}-allow-internal-traffic"
echo "Creating firewall rule: $FW_RULE_INTERNAL_NAME..."
gcloud compute firewall-rules create $FW_RULE_INTERNAL_NAME \
    --project=$PROJECT_ID \
    --network=$VPC_NAME \
    --action=ALLOW \
    --direction=INGRESS \
    --source-ranges=$SUBNET_CIDR \
    --rules=tcp:0-65535,udp:0-65535,icmp \
    --description="Allow internal traffic within the $SUBNET_NAME subnetwork"

# 4. Create the IAP SSH firewall rule
#    Allows TCP traffic on port 22 (SSH) only from Google's IAP service range.
export FW_RULE_IAP_SSH_NAME="${SUBNET_NAME}-allow-iap-ssh"
echo "Creating firewall rule: $FW_RULE_IAP_SSH_NAME..."
gcloud compute firewall-rules create $FW_RULE_IAP_SSH_NAME \
    --project=$PROJECT_ID \
    --network=$VPC_NAME \
    --action=ALLOW \
    --direction=INGRESS \
    --source-ranges=35.235.240.0/20 \
    --rules=tcp:22 \
    --description="Allow IAP-tunneled SSH connections to the $SUBNET_NAME subnetwork"

echo "Infrastructure creation commands generated."
echo "Remember to replace the SUBNET_CIDR if needed."

```

create deployment folder from the cluster blueprint
```
./gcluster create hpc-gpu-dws-gcp-slurm-v6.yaml -l ERROR --vars project_id=northam-ce-mlai-tpu
```

deploy HPC cluster using Terraform
```
./gcluster deploy ztan-hpc-gpu-dws
```

Create Controller SA
```
gcloud iam service-accounts create controllernode \
  --project=northam-ce-mlai-tpu \
  --display-name="Slurm Controller Node SA"
```

Create Compute SA
```
gcloud iam service-accounts create computenode \
  --project=northam-ce-mlai-tpu \
  --display-name="Slurm Compute Node SA"
```

Create Login SA (likely needed too, even if no error yet)
gcloud iam service-accounts create loginnode \
  --project=northam-ce-mlai-tpu \
  --display-name="Slurm Login Node SA"

Example roles for Controller SA (might need more)
```
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
```

SSH into the Login Node
Replace placeholders with your actual credentials. or using web UI
```
ssh your_username@login.node.cluster.address
```

You need a script file that tells Slurm what resources you need and what commands to run. Create a file named gpu_job.sbatch

Use the sbatch command to submit your script to the Slurm scheduler:
```
sbatch gpu_job.sbatch
```


```
# https://cloud.google.com/compute/docs/gpus/create-gpu-vm-a3u-a4
export PROJECT_ID="the-foo-bar"
# export MACHINE_TYPE="a3-ultragpu-8g"
export MACHINE_TYPE="a4-highgpu-8g"

# This image took like 10+ minutes to boot
# export IMAGE_PROJECT="debian-cloud"
# export IMAGE_FAMILY="debian-12"

# This worked
# https://cloud.google.com/ai-hypercomputer/docs/software-stack#os-image
export IMAGE_PROJECT="ubuntu-os-accelerator-images"
export IMAGE_FAMILY="ubuntu-accelerator-2404-amd64-with-nvidia-570"

# This image doesn't work
# export IMAGE_PROJECT="deeplearning-platform-release"
# export IMAGE_FAMILY="common-cu124"
# common-cu124-v20250325-debian-11-py310

export DISK_SIZE="200GB"
export ZONE="us-central1-b"
export INSTANCE_NAME="test-instance"
export NETWORK="projects/the-foo-bar/global/networks/default"
export SUBNET="projects/the-foo-bar/regions/us-central1/subnetworks/default"
export TERMINATION_ACTION="STOP"

gcloud config set project $PROJECT_ID
gcloud auth application-default set-quota-project $PROJECT_ID


gcloud beta compute instances create $INSTANCE_NAME  \
    --machine-type=$MACHINE_TYPE \
    --image-family=$IMAGE_FAMILY \
    --image-project=$IMAGE_PROJECT \
    --provisioning-model=SPOT \
    --instance-termination-action=$TERMINATION_ACTION \
    --zone=$ZONE \
    --boot-disk-type=hyperdisk-balanced \
    --boot-disk-size=$DISK_SIZE \
    --scopes=cloud-platform \
    --network-interface=nic-type=GVNIC,network=$NETWORK,subnet=$SUBNET
```

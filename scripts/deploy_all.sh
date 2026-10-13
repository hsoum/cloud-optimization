#!/usr/bin/env bash
# Copy bin/ to every worker VM and list the result. usage: ./scripts/deploy_all.sh
set -euo pipefail

ZONE="europe-west1-b"
VMS="cloudopt-vm1 cloudopt-vm2 cloudopt-vm3"

for w in cpu_task memory_task matrix_task sort_task; do
  [ -f "bin/$w" ] || { echo "error: bin/$w missing, compile it first" >&2; exit 1; }
done

for vm in $VMS; do
  echo "== $vm =="
  gcloud compute ssh "$vm" --zone="$ZONE" --command="mkdir -p ~/cloud-optimization"
  gcloud compute scp --recurse bin "$vm":~/cloud-optimization/ --zone="$ZONE"
  gcloud compute ssh "$vm" --zone="$ZONE" --command="chmod +x ~/cloud-optimization/bin/* && ls -lh ~/cloud-optimization/bin"
done
echo "Deployment finished on: $VMS"

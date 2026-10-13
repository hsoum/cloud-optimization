#!/bin/bash
# Usage: ./scripts/run_task.sh TASK_ID WORKLOAD SIZE VM ZONE

if [ "$#" -ne 5 ] || [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ]; then
  echo "Usage: $0 TASK_ID WORKLOAD SIZE VM ZONE" >&2
  exit 2
fi

TASK_ID=$1; WORKLOAD=$2; SIZE=$3; VM=$4; ZONE=$5

mkdir -p results

gcloud compute ssh "$VM" --zone="$ZONE" \
  --command="cd ~/cloud-optimization && ./bin/$WORKLOAD --size $SIZE" \
  > "results/$TASK_ID.out" 2> "results/$TASK_ID.err"
RC=$?
echo "$VM" > "results/$TASK_ID.vm"

echo "$RC" > "results/$TASK_ID.status"

if [ "$RC" -ne 0 ]; then
  echo "[ERREUR] $TASK_ID ($WORKLOAD $SIZE) sur $VM : code $RC" | tee -a "results/$TASK_ID.err" >&2
else
  echo "[OK] $TASK_ID sur $VM"
fi
exit "$RC"

#!/bin/bash
ZONE=${1:?usage: run_all.sh ZONE}
CSV=data/allocation_manual.csv
mkdir -p results

while IFS=, read -r id wl size vm; do
  ./scripts/run_task.sh "$id" "$wl" "$size" "$vm" "$ZONE" &
done < <(tail -n +2 "$CSV")

wait
echo "All tasks completed"

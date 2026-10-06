# Cloud Optimization — Distributed Task Scheduling on GCP

Group 19 (Yuba, Amani, Hichem), ESILV Cloud Optimization semester project.

Given a set of tasks and a set of virtual machines, where should each task run? This repository
holds the workloads, the measurements, the execution scripts and, later, the scheduler,
orchestrator and analyzer that answer that question on Google Compute Engine.

## Layout

```text
workloads/   the four reference Go programs, unmodified
bin/         compiled workloads (built locally, not committed)
data/        measurements and allocation files
scripts/     shell helpers (benchmark.sh from TD1, then the TD3 deployment and execution scripts)
results/     reports and run outputs
docs/        session write-ups (TD1.md)
```

## First-time setup, for each teammate

```bash
git clone git@github.com:hsoum/cloud-optimization.git   # get the repository
cd cloud-optimization                                    # always work from the project root
echo "my-label" > .machine                               # your machine label for benchmark rows (not committed)
for w in cpu_task memory_task matrix_task sort_task; do go build -o "bin/$w" "workloads/$w.go"; done   # build the four static x86-64 binaries
```

Then write your own `data/machine_<label>.txt`, as described in [docs/TD1.md](docs/TD1.md).

## GCP

| Setting | Value |
|---|---|
| Project | `cloud-optimization-510813`, shared, all three of us are owners |
| Zone | `europe-west1-b`, the project default |
| VM names | `cloudopt-vm1`, `cloudopt-vm2`, `cloudopt-vm3` |
| Quota | 12 vCPU in total across all running VMs |
| Credits | 150 USD for the whole group, on one billing account |

```bash
gcloud config set project cloud-optimization-510813   # point your gcloud at the shared project
gcloud config set compute/zone europe-west1-b         # same zone for every VM
gcloud compute instances list                         # check what is running, before and after each session
```

Every running VM spends the shared credits from the moment it boots: **stop or delete the VMs at
the end of each session.**

## Working together

- `main` always works. New work goes on a branch (`feature/...`), then a pull request that another
  member reviews before it is merged.
- `.gitattributes` forces LF line endings. A shell script or CSV saved with Windows line endings
  breaks on the VMs (`cloudopt-vm1\r` → "instance not found").
- Never commit keys, service-account files or `.env` files; `.gitignore` blocks the usual names.
- An experiment's inputs and outputs are committed together, so every figure in the report can be
  traced back to the run that produced it.

## Sessions

- **TD1**, local workloads and benchmarking: [docs/TD1.md](docs/TD1.md)
- **TD3**, distributed orchestration: deployment and run instructions go here together with
  `scripts/run_task.sh` and `scripts/run_all.sh`.

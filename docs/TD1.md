# TD1 — Local Workloads and Benchmarking

Local workload characterisation for the Cloud Optimization semester project
(distributed task scheduling on GCP). This directory produces the **local baseline**
column of the workload/machine cost table; later TDs add one column per GCP machine type.

**Group 19** — Yuba, Amani, Hichem.
Session: 2026-09-11. Instructor: Daniel Wladdimiro.

## Environment

Everything below was measured on one machine. Runtimes are **not** comparable with
figures collected elsewhere unless the specs match.

| Property | Value |
|---|---|
| Distribution | Ubuntu 24.04.4 LTS |
| Environment | **WSL2** (a virtual machine on a Windows host, not bare metal) |
| Kernel | Linux 6.6.87.2-microsoft-standard-WSL2 |
| CPU | Intel Core Ultra 9 285H |
| Cores / threads | 16 physical cores, 1 thread per core — **no SMT**, so logical CPUs = physical cores |
| L2 / L3 cache | 48 MiB (16 instances) / **24 MiB (shared)** |
| RAM | 19 GiB total, ~16 GiB available |
| Go | go1.22.2 linux/amd64 (`golang-go` from the Ubuntu archive) |
| Timer | GNU `time` (`/usr/bin/time`), **not** the shell builtin |
| Filesystem | native ext4 under `$HOME` — deliberately **not** `/mnt/c`, whose Windows mount is far slower and would contaminate every measurement |

Full raw capture: `data/machine_local.txt` (the filename the TD sheet asks for) and an identical
`data/machine_ultra9-285h.txt` (the per-machine name the benchmark script looks for). Same content.

WSL2 being a VM is worth declaring: it is a valid environment for this TD, but it is
exactly the kind of environment difference the sheet warns about.

## Layout

```
.machine     this computer's label, one line (e.g. ultra9-285h); each teammate sets their own
workloads/   the four provided .go sources, unmodified
bin/         compiled binaries (go build output, not committed)
scripts/     benchmark.sh, the measurement runner
data/        benchmark_local.csv + machine_<label>.txt specs + raw/ per-run JSON
results/     analysis and figures
```

## Reproducing

```bash
# 1. compile — static native binaries, no Go toolchain needed to run them
go build -o bin/cpu_task    workloads/cpu_task.go
go build -o bin/memory_task workloads/memory_task.go
go build -o bin/matrix_task workloads/matrix_task.go
go build -o bin/sort_task   workloads/sort_task.go

# 2. measure — usage: scripts/benchmark.sh <workload> <size> [runs]
for size in 2500000 5000000 10000000; do scripts/benchmark.sh cpu_task    "$size" 3; done
for size in 256 512 1024;            do scripts/benchmark.sh memory_task "$size" 3; done
for size in 500 1000 1500;           do scripts/benchmark.sh matrix_task "$size" 3; done
for size in 5000000 10000000 20000000; do scripts/benchmark.sh sort_task  "$size" 3; done
```

Output accumulates in `data/benchmark_local.csv` with columns
`machine,workload,size,run,runtime_s,max_rss_kb`.

## Chosen sizes, and why they are not the sheet's

The sheet's suggested sizes all completed in **under 0.25 s** on this CPU — several in
under 0.01 s, which is indistinguishable from process startup and scheduler noise. The
sheet anticipates this ("may need to be adapted to your machine"). Sizes were scaled up
until the largest run took roughly 2 s, and chosen so consecutive steps are clean
doublings where possible, which makes the scaling question directly answerable.

| Workload | Sheet suggested | **Used here** | Largest run |
|---|---|---|---|
| `cpu_task` | 200k / 500k / 1M | **2.5M / 5M / 10M** | 2.12 s |
| `memory_task` | 128 / 256 / 512 MB | **256 / 512 / 1024 MB** | 1.13 s |
| `matrix_task` | 200 / 400 / 600 | **500 / 1000 / 1500** | 4.50 s |
| `sort_task` | — (absent from the sheet's campaign) | **5M / 10M / 20M** | 1.87 s |

`memory_task --passes` was left at its default of 5 for the entire campaign; changing it
would make sizes incomparable.

## Measurement decisions

- **`runtime_s` is the GNU `time` wall clock**, not the program's own JSON `runtime_s`.
  The four programs start their internal stopwatches at different points — `sort_task`
  excludes generating its input, `matrix_task` excludes allocating and filling A and B —
  so the internal figures are not comparable across workloads. Both are kept: the CSV
  holds the wall clock, `data/raw/` holds the per-run JSON.
- **One CSV row per execution, never an average.** Variability between repetitions is
  itself a result; it is what will distinguish a real difference between two VMs from noise.
- **A failed run writes no row.** A half-recorded failure is worse than a missing one.
- **Every row carries the machine that produced it.** Three students on three different
  laptops produce three incomparable sets of runtimes; without a machine column, concatenating
  their CSVs would silently mix them. The sheet warns against exactly this. The label also
  names the spec file (`data/machine_<label>.txt`), so a row can always be traced to the
  hardware behind it.
- `memory_task` emits `size_mb` where the other three emit `size` — any automated
  collector written in TD3 must handle both.

## Running this on another machine

Each teammate does this once, then runs the campaign above unchanged.

```bash
echo "my-label" > .machine          # short, no comma, no spaces - identifies your rows
{ echo "=== uname -a ==="; uname -a; echo; echo "=== lscpu ==="; lscpu; \
  echo; echo "=== free -h ==="; free -h; echo; echo "=== go version ==="; go version; } \
  > "data/machine_$(cat .machine).txt"
```

`MACHINE=other-label scripts/benchmark.sh ...` overrides the label for a single run, which is
what to use when benchmarking a GCP VM from your own shell in TD2.

Merging three CSVs is then a concatenation that keeps one header:

```bash
{ head -1 a.csv; tail -qn +2 a.csv b.csv c.csv; } > benchmark_all.csv
```

The script refuses to append to a CSV whose header does not match, so a stale file cannot be
silently mixed with new rows.

## Results

All figures below are from `ultra9-285h` (specs above). Mean of 3 runs.
Full data in `data/benchmark_local.csv`.

| Workload | Size | Mean (s) | Min | Max | Peak RSS |
|---|---|---|---|---|---|
| cpu_task | 2 500 000 | 0.283 | 0.28 | 0.29 | 2 MB |
| cpu_task | 5 000 000 | 0.750 | 0.75 | 0.75 | 2 MB |
| cpu_task | 10 000 000 | 2.120 | 2.02 | 2.22 | 2 MB |
| memory_task | 256 | 0.300 | 0.27 | 0.36 | 258 MB |
| memory_task | 512 | 0.547 | 0.49 | 0.63 | 514 MB |
| memory_task | 1024 | 1.127 | 1.05 | 1.28 | 1027 MB |
| matrix_task | 500 | 0.073 | 0.07 | 0.08 | 8 MB |
| matrix_task | 1000 | 0.550 | 0.54 | 0.56 | 25 MB |
| matrix_task | 1500 | 4.503 | 4.13 | 4.73 | 54 MB |
| sort_task | 5 000 000 | 0.423 | 0.41 | 0.43 | 40 MB |
| sort_task | 10 000 000 | 0.863 | 0.85 | 0.89 | 79 MB |
| sort_task | 20 000 000 | 1.870 | 1.83 | 1.91 | 155 MB |

## Conclusion

**The four workloads stress different resources, and that is the point.** `cpu_task` runs
in a flat 2 MB regardless of size — it is pure arithmetic. `memory_task` is the mirror
image: its runtime tracks the megabytes it touches almost exactly, and its RSS is the
size parameter itself. `sort_task` and `matrix_task` sit in between, using memory in
proportion to input but doing real work on it.

**None of them uses more than one core.** There is not a single goroutine in the four
sources, so 15 of the 16 cores are idle throughout every run. This is the premise of the
project rather than a defect: because one task cannot fill a machine, the scheduling
question becomes how many tasks to *pack* onto each VM.

**Scaling mostly matches the algorithmic cost, with one sharp exception.**

| Workload | Step | Observed | Predicted | |
|---|---|---|---|---|
| cpu_task | 5M → 10M | 2.83× | 2.83× ($n^{1.5}$) | matches |
| memory_task | 512 → 1024 | 2.06× | 2× (linear) | matches |
| sort_task | 10M → 20M | 2.17× | ~2.1× ($n\log n$) | matches |
| matrix_task | 500 → 1000 | 7.53× | 8× ($N^3$) | matches |
| matrix_task | **1000 → 1500** | **8.19×** | **3.38×** ($N^3$) | **does not match** |

The last row is a cache effect, not an anomaly in the code. `matrix_task` holds three
dense $N \times N$ float64 matrices, so its working set is $3N^2 \times 8$ bytes:

| N | Working set | vs. 24 MiB L3 |
|---|---|---|
| 500 | 6 MB | fits easily |
| 1000 | 24 MB | exactly at the edge |
| 1500 | 54 MB | 2.25× over — falls off |

The naive triple loop traverses one operand against the cache grain, so once the working
set no longer fits in L3, inner-loop steps become DRAM round-trips. Supporting evidence:
`matrix_task` at N=1500 has the widest spread of any measurement here (4.13–4.73 s, ~14%),
the signature of a memory-bound run, whereas `cpu_task` at its largest size varies by ~5%.

**This is the finding that matters for the project.** Three of the four workloads can be
ranked across GCP machine types from clock speed alone. `matrix_task` cannot — its cost
depends on the VM's **cache hierarchy**, which is not visible in a vCPU count or a price
list. Any scheduler that models task cost as a single scalar per machine type will
mispredict it.

## Open questions for the instructor

- Is the group of three formed, and where should the group repository live?
- For the CSV `runtime_s`, GNU `time` wall clock or the program's own JSON figure?
- Is WSL2 acceptable as the local environment?
- The CM1 capture said "QEMU for TD1 to prepare", but TD1 uses no virtualization at all.
  Is QEMU coming in a later TD?

# Cloud Optimization - Reference Go Workloads

These workloads are intentionally simple. Their goal is to provide different resource profiles for the semester project.

## 1. CPU workload

Tests integers for primality.

```bash
go build -o cpu_task cpu_task.go
./cpu_task --size 200000
./cpu_task --size 500000
./cpu_task --size 1000000
```

`--size` = maximum integer tested.

## 2. Memory workload

Allocates and repeatedly touches a large `[]uint64`.

```bash
go build -o memory_task memory_task.go
./memory_task --size 128
./memory_task --size 256
./memory_task --size 512
```

`--size` = allocated memory in MB.

Optional:

```bash
./memory_task --size 256 --passes 10
```

## 3. Matrix workload

Naive dense matrix multiplication.

```bash
go build -o matrix_task matrix_task.go
./matrix_task --size 200
./matrix_task --size 400
./matrix_task --size 600
```

`--size` = matrix dimension N for NxN matrices.

## 4. Sorting workload

Generates and sorts a deterministic array of integers.

```bash
go build -o sort_task sort_task.go
./sort_task --size 1000000
./sort_task --size 5000000
./sort_task --size 10000000
```

`--size` = number of integers.

## Output

Each program prints one JSON object, for example:

```json
{"task":"cpu_task","size":500000,"runtime_s":0.241,"primes_found":41538}
```

The JSON output is deliberately machine-readable so it can later be collected by the orchestrator.

## Suggested workflow

Students can compile everything with:

```bash
mkdir -p bin
go build -o bin/cpu_task cpu_task.go
go build -o bin/memory_task memory_task.go
go build -o bin/matrix_task matrix_task.go
go build -o bin/sort_task sort_task.go
```

Then benchmark with commands such as:

```bash
/usr/bin/time -v ./bin/cpu_task --size 500000
/usr/bin/time -v ./bin/memory_task --size 256
/usr/bin/time -v ./bin/matrix_task --size 400
/usr/bin/time -v ./bin/sort_task --size 5000000
```

The exact sizes should be calibrated once on the ESILV lab machines and once on the selected GCP VM types so that individual tasks remain long enough to measure but short enough for a TD session.

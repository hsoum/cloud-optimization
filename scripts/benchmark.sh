#!/usr/bin/env bash
set -euo pipefail                        # abort on any error, undefined variable, or broken pipe stage

BIN_DIR="${BIN_DIR:-bin}"                # directory holding the compiled workloads, overridable from the environment
DATA_DIR="${DATA_DIR:-data}"             # directory for all output, overridable the same way
CSV="${DATA_DIR}/benchmark_local.csv"    # the single CSV that accumulates every measurement
JSON_DIR="${DATA_DIR}/raw"               # per-run JSON output kept alongside, so nothing is thrown away

HEADER="machine,workload,size,run,runtime_s,max_rss_kb"   # the exact column layout every row must match

# The machine label identifies which computer produced a row, so three students' CSVs can be
# concatenated without the runtimes becoming meaningless. Resolution order, first hit wins:
#   1. the MACHINE environment variable, for a one-off override
#   2. the .machine file in the project root, which is how each teammate sets theirs permanently
#   3. the short hostname, so the script still works with no configuration at all
MACHINE="${MACHINE:-$(cat .machine 2>/dev/null || hostname -s)}"

usage() {                                # called when the script is invoked incorrectly
  echo "usage: $0 <workload> <size> [runs]" >&2   # send usage to stderr so it never lands in a CSV
  echo "  MACHINE=<label> overrides the machine label (currently: ${MACHINE})" >&2   # document the override
  exit 2                                 # exit code 2 means "bad invocation", distinct from a run failure
}

[ "$#" -ge 2 ] || usage                  # a workload name and a size are both mandatory

WORKLOAD="$1"                            # e.g. cpu_task
SIZE="$2"                                # the value passed through to --size
RUNS="${3:-3}"                           # repetitions; the sheet asks for three, so that is the default

EXE="${BIN_DIR}/${WORKLOAD}"             # full path of the binary this invocation will run

case "$MACHINE" in                       # a comma in the label would silently shift every later column
  ""|*,*|*[[:space:]]*)                  # reject empty labels, embedded commas, and embedded whitespace
    echo "error: machine label '${MACHINE}' must be non-empty and contain no comma or whitespace" >&2
    exit 2 ;;                            # exit 2: this is a configuration mistake, not a failed run
esac

if [ ! -x "$EXE" ]; then                 # requirement 7: fail clearly if the executable is missing
  echo "error: '$EXE' not found or not executable - compile it first with go build" >&2
  exit 1                                 # exit code 1 means "the experiment could not be run"
fi

mkdir -p "$DATA_DIR" "$JSON_DIR"         # create the output directories if this is the first run

# A runtime is uninterpretable without the specs of the machine that produced it, and the TD sheet
# warns against comparing across student computers without them. Warn rather than abort, so a
# measurement session is never blocked by a missing text file.
SPEC="${DATA_DIR}/machine_${MACHINE}.txt"   # the spec file this machine label is expected to have
if [ ! -f "$SPEC" ]; then                # only a warning: the rows are still worth collecting
  echo "warning: no machine spec at '${SPEC}' - record one with uname/lscpu/free before sharing this CSV" >&2
fi

if [ ! -f "$CSV" ]; then                 # write the header exactly once, never on later appends
  echo "$HEADER" > "$CSV"                # column names: machine first, then the sheet's five
else                                     # the CSV already exists, so confirm it has the layout we are about to append
  existing="$(head -1 "$CSV")"           # read back only the header line
  if [ "$existing" != "$HEADER" ]; then  # appending to a differently-shaped CSV would corrupt the whole file
    echo "error: '${CSV}' has header '${existing}'" >&2
    echo "       expected '${HEADER}' - migrate the old file before appending" >&2
    exit 1                               # refuse to write rather than produce a silently mixed CSV
  fi
fi

for run in $(seq 1 "$RUNS"); do          # one iteration of this loop produces exactly one CSV row
  timing="$(mktemp)"                     # scratch file where GNU time writes its own measurements
  json="${JSON_DIR}/${MACHINE}_${WORKLOAD}_${SIZE}_${run}.json"   # machine in the name so merged JSON never collides

  # -f '%e %M' asks GNU time for two numbers only: elapsed wall-clock seconds, and peak RSS in kilobytes.
  # -o writes them to the scratch file, keeping them out of the workload's own stdout.
  if /usr/bin/time -f '%e %M' -o "$timing" "$EXE" --size "$SIZE" > "$json"; then
    read -r elapsed rss < "$timing"      # split GNU time's single output line into its two fields
    echo "${MACHINE},${WORKLOAD},${SIZE},${run},${elapsed},${rss}" >> "$CSV"   # one raw, unaveraged measurement
    echo "ok  ${MACHINE} ${WORKLOAD} size=${SIZE} run=${run}  ${elapsed}s  ${rss}KB" >&2   # progress on stderr
  else
    echo "error: ${MACHINE} ${WORKLOAD} size=${SIZE} run=${run} failed - no row written" >&2   # requirement 7 again
    rm -f "$timing"                      # clean up the scratch file before leaving
    exit 1                               # never let a failed execution produce a silent or partial row
  fi

  rm -f "$timing"                        # remove the scratch file between repetitions
done

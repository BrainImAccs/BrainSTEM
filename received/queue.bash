#!/usr/bin/env bash
#
# This scripts uses GNU parallel for a simple queueing system, so that a certain number of jobs can be processed in
# parallel.
#

# Get the path to the directory of this script
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source setup.brainstem.bash
. "${__dir}/../setup.brainstem.bash"

# The directory of this queue and it's queue file 
# received.bash (in this case) will write new jobs to the queue file 
queueDir="${__dir}/data"
queueFile="${queueDir}/queue"

# Check if directory for queue file exists, otherwise create it
if [[ ! -d "${queueDir}" ]]; then mkdir -p "${queueDir}"; fi

# Start fresh; remove the old queue file
if [[ -e "${queueFile}" ]]; then rm "${queueFile}"; fi

# GNU parallel only starts processing when the queue has been full once, after that, jobs are started
# as they are added. Therefore, we add a number of dummy jobs, which are ignored by startJob.bash.
# See: https://www.gnu.org/software/parallel/man.html#EXAMPLE:-GNU-Parallel-as-queue-system-batch-manager
for i in $(seq $jobSlots); do
  echo "parallelSimpleQueueSystemStartup" >> "${queueFile}"
done

# Start GNU parallel as a simple queue manager to process X jobs in the queue in parallel
(tail -f -n+0 "${queueFile}" | ${parallel} \
  --max-procs $jobSlots \
  --ungroup \
  "${__dir}/../tools/startJob.bash" ::: || true)

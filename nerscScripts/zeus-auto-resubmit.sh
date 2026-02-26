#!/bin/bash
#
# Auto-resubmit wrapper for preemptible Zeus jobs
# This script monitors the job and resubmits if preempted
#
# Usage: ./zeus-auto-resubmit.sh [max_resubmits]
#   max_resubmits: maximum number of times to resubmit (default: 10)
#
# Zeus checkpoints every 'nsteps' iterations to the output chain file
# and saves sampler state for resumption.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BATCH_SCRIPT="${SCRIPT_DIR}/cosmosis-batch-zeus-preempt.sh"
CHAIN_FILE="${PSCRATCH}/chains/winter2025/y3cpp/chains/zeus_full.txt"

# Zeus parameters from ini file
TARGET_SAMPLES=100000
WALKERS=44

MAX_RESUBMITS=${1:-10}
RESUBMIT_COUNT=0
CHECK_INTERVAL=300  # Check every 5 minutes

echo "=========================================="
echo "Zeus Auto-Resubmit Wrapper"
echo "=========================================="
echo "Max resubmits: ${MAX_RESUBMITS}"
echo "Batch script: ${BATCH_SCRIPT}"
echo "Chain file: ${CHAIN_FILE}"
echo "Target samples: ${TARGET_SAMPLES} (x${WALKERS} walkers)"
echo ""

# Function to check if Zeus has converged (reached target samples)
check_convergence() {
    if [[ -f "${CHAIN_FILE}" ]]; then
        # Count lines in chain file (each line is one sample)
        local nlines=$(wc -l < "${CHAIN_FILE}" 2>/dev/null || echo 0)
        local nsamples=$((nlines / WALKERS))
        echo "Current samples: ${nsamples} / ${TARGET_SAMPLES}"
        if [[ ${nsamples} -ge ${TARGET_SAMPLES} ]]; then
            echo "Convergence reached!"
            return 0
        fi
    fi
    return 1
}

# Function to submit job and get job ID
submit_job() {
    local job_id=$(sbatch "${BATCH_SCRIPT}" 2>&1 | grep -oP '\d+')
    echo "${job_id}"
}

# Function to get job state
get_job_state() {
    local job_id=$1
    squeue -j "${job_id}" -h -o "%T" 2>/dev/null
}

# Main loop
while [[ ${RESUBMIT_COUNT} -lt ${MAX_RESUBMITS} ]]; do

    # Check if already converged
    if check_convergence; then
        echo "Zeus has reached target samples! Exiting."
        exit 0
    fi

    # Submit job
    echo "[$(date)] Submitting job (attempt $((RESUBMIT_COUNT + 1))/${MAX_RESUBMITS})..."
    JOB_ID=$(submit_job)

    if [[ -z "${JOB_ID}" ]]; then
        echo "ERROR: Failed to submit job"
        exit 1
    fi

    echo "[$(date)] Job submitted with ID: ${JOB_ID}"

    # Monitor job
    while true; do
        sleep ${CHECK_INTERVAL}

        STATE=$(get_job_state "${JOB_ID}")

        if [[ -z "${STATE}" ]]; then
            # Job no longer in queue - check why
            SACCT_INFO=$(sacct -j "${JOB_ID}" --format=State,ExitCode -n -P 2>/dev/null | head -1)
            JOB_STATE=$(echo "${SACCT_INFO}" | cut -d'|' -f1)

            echo "[$(date)] Job ${JOB_ID} finished with state: ${JOB_STATE}"

            if [[ "${JOB_STATE}" == "COMPLETED" ]]; then
                # Check if actually converged
                if check_convergence; then
                    echo "Zeus completed successfully!"
                    exit 0
                else
                    echo "Job completed but Zeus not converged. Resubmitting..."
                fi
            elif [[ "${JOB_STATE}" == "PREEMPTED" ]] || [[ "${JOB_STATE}" == "CANCELLED" ]] || [[ "${JOB_STATE}" == "TIMEOUT" ]]; then
                echo "Job was ${JOB_STATE}. Will resubmit..."
            elif [[ "${JOB_STATE}" == "FAILED" ]]; then
                echo "Job FAILED. Check logs. Exiting."
                exit 1
            else
                echo "Unknown job state: ${JOB_STATE}. Will attempt resubmit..."
            fi

            break  # Exit inner loop to resubmit
        fi

        echo "[$(date)] Job ${JOB_ID} state: ${STATE}"
    done

    RESUBMIT_COUNT=$((RESUBMIT_COUNT + 1))

    # Small delay before resubmitting
    sleep 10
done

echo "Reached maximum resubmit count (${MAX_RESUBMITS}). Exiting."
echo "Check if Zeus has converged or if there are persistent issues."
exit 1

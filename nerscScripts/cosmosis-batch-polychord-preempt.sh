#!/bin/bash

# PolyChord sampler batch script - preemptible version
# Uses gpu_preempt QOS for faster scheduling
# Job may be preempted but will resume from checkpoint
#
# N.B.: Our code expects that each MPI rank can see all the GPUs on each node.
# Make sure to keep 'ntasks' = 4 * 'nodes', because always want 4 ranks per node.

#SBATCH -A des_g
#SBATCH -C gpu
#SBATCH -q preempt
#SBATCH -t 2-00:00:00
#SBATCH --nodes=4
#SBATCH --ntasks=16
#SBATCH --ntasks-per-node=4
#SBATCH -c 32
#SBATCH --gpus-per-task=1
#SBATCH --gpu-bind=none
#SBATCH -L scratch:1
#SBATCH --mail-type=begin,end,fail
#SBATCH --mail-user=jesteves@fas.harvard.edu
#SBATCH -J polychord_preempt
#SBATCH -o %x-%j.out

export SLURM_CPU_BIND="cores"

# Load CUDA toolkit for GPU libraries
module load cudatoolkit/12.2

export TOP_DIR=/global/common/software/des/jesteves
export COSMOSIS_REPO_DIR=${TOP_DIR}/cosmosis
export CSL_DIR=${TOP_DIR}/cosmosis-standard-library

export INTEGRATION_TOOLS_DIR=${TOP_DIR}/y3_pipe_under
export Y3PIPE_DIR=${TOP_DIR}/y3_cluster_cpp
export Y3_CLUSTER_WORK_DIR=${Y3PIPE_DIR}/release-build
export Y3_CLUSTER_CPP_DIR=${Y3PIPE_DIR}
export COSMOSIS_STANDARD_LIBRARY=${CSL_DIR}

export CUBA_DIR=${INTEGRATION_TOOLS_DIR}/cuba
export CUBA_CPP_DIR=$INTEGRATION_TOOLS_DIR/cubacpp
export GPU_INT_DIR=${INTEGRATION_TOOLS_DIR}/gpuintegration

export OMP_NUM_THREADS=4

# Set up CosmoSIS
source ${COSMOSIS_REPO_DIR}/setup-cosmosis-nersc /global/common/software/des/common/Conda_Envs/y3cl_je

export MY_TOP_DIR=/global/common/software/des/$(id -un)
export Y3PIPE_DIR=${MY_TOP_DIR}/y3_cluster_cpp
export Y3_CLUSTER_CPP_DIR=${Y3PIPE_DIR}
export Y3_CLUSTER_WORK_DIR=${Y3PIPE_DIR}/release-build

# Create output directory for PolyChord native files
mkdir -p ${PSCRATCH}/chains/winter2025/y3cpp/chains/polychord_output/clusters

cd ${PSCRATCH}/chains/winter2025/y3cpp/cosmosisModels/
srun -n ${SLURM_NTASKS} cosmosis --mpi y1_mock_polychord.ini

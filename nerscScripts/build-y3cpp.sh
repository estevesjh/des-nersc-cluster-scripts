#!/bin/bash
#SBATCH -A des_g
#SBATCH -C gpu
#SBATCH -q interactive
#SBATCH -t 00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --gpus=4
#SBATCH -J build_y3cpp
#SBATCH -o %x-%j.out

export TOP_DIR=/global/common/software/des/jesteves
export COSMOSIS_REPO_DIR=${TOP_DIR}/cosmosis
export CSL_DIR=${TOP_DIR}/cosmosis-standard-library

export INTEGRATION_TOOLS_DIR=${TOP_DIR}/y3_pipe_under
export Y3PIPE_DIR=${TOP_DIR}/y3_cluster_cpp
export Y3_CLUSTER_WORK_DIR=${Y3PIPE_DIR}/release-build
export Y3_CLUSTER_CPP_DIR=${Y3PIPE_DIR}
export COSMOSIS_STANDARD_LIBRARY=${CSL_DIR}

export CUBA_DIR=${INTEGRATION_TOOLS_DIR}/cuba
export CUBA_CPP_DIR=${INTEGRATION_TOOLS_DIR}/cubacpp
export GPU_INT_DIR=${INTEGRATION_TOOLS_DIR}/gpuintegration

export OMP_NUM_THREADS=4

# Set up CosmoSIS first
source ${COSMOSIS_REPO_DIR}/setup-cosmosis-nersc /global/common/software/des/common/Conda_Envs/y3cl_je

# Load cudatoolkit AFTER CosmoSIS setup (so it doesn't get overridden)
module load cudatoolkit/12.2

echo "=== Environment ==="
which nvcc && nvcc --version 2>&1 | tail -1
which CC
which cmake
echo "CONDA_PREFIX=$CONDA_PREFIX"

# Clean and rebuild
echo "=== Cleaning old build ==="
rm -rf ${Y3PIPE_DIR}/release-build
mkdir -p ${Y3PIPE_DIR}/release-build
cd ${Y3PIPE_DIR}/release-build

echo "=== Running cmake ==="
cmake \
  -DUSE_CUDA=On \
  -DY3GCC_TARGET_ARCH=80-real \
  -DPAGANI_DIR=${GPU_INT_DIR} \
  -DGSL_ROOT_DIR=${CONDA_PREFIX} \
  -DCMAKE_MODULE_PATH=${CUBA_CPP_DIR}/cmake/modules \
  -DCUBACPP_DIR=${CUBA_CPP_DIR} \
  -DCUBA_DIR=${CUBA_DIR} \
  -DCMAKE_BUILD_TYPE=Release \
  -G Ninja \
  ${Y3_CLUSTER_CPP_DIR}

if [ $? -ne 0 ]; then
    echo "CMAKE FAILED"
    exit 1
fi

echo "=== Building with ninja ==="
ninja

if [ $? -ne 0 ]; then
    echo "BUILD FAILED"
    exit 1
fi

echo "=== Running tests ==="
srun -n 1 ctest -j 4

echo "=== Build complete ==="
ls -la src/modules/gt_mock_gpu/*.so 2>/dev/null

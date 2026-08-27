# working directory, use high performance shared area on perlmutter

#export TOP_DIR=/global/common/software/des/annis # we moved to johnny's top dir on Mar, 2025
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

# We set OMP_NUM_THREADS to avoid oversubscribing the CPU cores.
# This value has not been carefully tuned.
export OMP_NUM_THREADS=4

# Now set up CosmoSIS
source ${COSMOSIS_REPO_DIR}/setup-cosmosis-nersc /global/common/software/des/common/Conda_Envs/y3cl_je
#source ${COSMOSIS_REPO_DIR}/setup-cosmosis-nersc /global/common/software/des/common/Conda_Envs/cosmosis-global # this is outdated



## use my own installation
export MY_TOP_DIR=/global/common/software/des/yyzhang/temp_dir
export Y3PIPE_DIR=${MY_TOP_DIR}/y3_cluster_cpp
export Y3_CLUSTER_CPP_DIR=${Y3PIPE_DIR}
export Y3_CLUSTER_WORK_DIR=${Y3PIPE_DIR}/release-build
cd ${Y3PIPE_DIR};
short-prompt

cd ${COSMOSIS_REPO_DIR}
# Note that the following uses a script only found in
# the `annis/cosmosis` fork of the repository, and there
# only in the `perlmutter` branch.
source setup-cosmosis-nersc /global/common/software/des/common/Conda_Envs/cosmosis-global

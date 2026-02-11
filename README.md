# Y3 Cluster Cosmology Pipeline (y3cpp) - Winter 2025

MCMC chain runs for DES Y3 galaxy cluster cosmology using CosmoSIS on NERSC Perlmutter.

## Overview

This project runs Bayesian parameter estimation for cluster abundance and weak lensing observables using mock data from the Buzzard simulation (v1.9.8). The analysis pipeline is built on CosmoSIS and uses GPU-accelerated numerical integration modules running on Perlmutter's GPU nodes.

## Directory Structure

```
y3cpp/
├── cosmosisModels/          # CosmoSIS configuration files
│   ├── y1_mock_emcee.ini    # Pipeline config using the emcee sampler
│   ├── y1_mock_metro.ini    # Pipeline config using the Metropolis sampler
│   ├── y1_mock_values.ini   # Cosmological & cluster abundance parameter priors
│   ├── simple_chain.txt     # Output chain (emcee, omega_m 1-param fit)
│   └── simple_chain.sampler_status  # Sampler state checkpoint
├── chains/                  # Chain output files
│   └── emcee_omegam_1p.txt  # Emcee chain sampling omega_m (1 free parameter)
├── nerscScripts/            # SLURM batch submission scripts & logs
│   ├── cosmosis-interactive-batch-8-emcee.sh   # 4-node GPU job for emcee
│   ├── cosmosis-interactive-batch-8-metro.sh   # 4-node GPU job for Metropolis
│   └── slurm-*.out          # Job output logs
└── README.md
```

## Pipeline Modules

The CosmoSIS pipeline runs the following modules in sequence:

1. **consistency** - Translates between parameterizations
2. **camb** - Boltzmann solver for matter power spectra (Takahashi halofit)
3. **mf_tinker** - Tinker halo mass function
4. **halo_model** - Builds projected correlation functions (Wp, gamma_t) from NFW profiles
5. **sigmaCritInv** - Computes inverse critical surface density using a precomputed beta lookup table
6. **numberCountsMock** - GPU-accelerated cluster number count predictions (Pagani integration)
7. **gammaCent** - GPU-accelerated mean tangential shear around cluster centers
8. **shear** - Builds gamma_t observable predictions
9. **likelihoods** - Computes likelihood against the mock data vector

## Sampled Parameters

Currently running a 1-parameter fit varying **omega_m** (matter density fraction) with a flat prior [0.1, 0.9]. All other cosmological and cluster abundance parameters are held fixed at fiducial values (see `y1_mock_values.ini`).

Key fixed parameters include:
- h0 = 0.6726, omega_b = 0.045, n_s = 0.963, sigma8 = 0.91
- Cluster mass-observable relation (MOR) parameters from Costanzi et al. 2019

## Running on NERSC Perlmutter

Jobs are submitted from `nerscScripts/` using 4 GPU nodes (16 MPI ranks, 4 per node):

```bash
sbatch cosmosis-interactive-batch-8-emcee.sh   # emcee sampler
sbatch cosmosis-interactive-batch-8-metro.sh   # Metropolis sampler
```

The scripts set up the CosmoSIS environment via:
```
source ${COSMOSIS_REPO_DIR}/setup-cosmosis-nersc <conda_env>
```

SLURM configuration: account `des_g`, GPU constraint, debug queue, 30-minute walltime.

## Dependencies

- CosmoSIS + CosmoSIS Standard Library
- y3_cluster_cpp (halo model and observable modules)
- GPU integration libraries (CUBA, cubacpp, gpuintegration)
- Conda environment: `y3cl_jesteves`
- Mock data: `dataVec_mock_May10th2023.npz` (Buzzard v1.9.8)

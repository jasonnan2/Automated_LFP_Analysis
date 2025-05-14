# Automated LFP Cleaning and Processing

This package provides functions for cleaning and modular referencing local field potential (LFP) recordings.

It is designed to work with both raw and epoched LFP data stored as 3D arrays (channels × time × trials) and supports common preprocessing operations such as broadband noise removal, bad trial/channel detection, and flexible re-referencing.

## Table of Contents
- [Installation](https://github.com/jasonnan2/Automated_LFP_Analysis/new/main?filename=README.md#installation)
- [Function Overview](https://github.com/jasonnan2/Automated_LFP_Analysis/new/main?filename=README.md#functionoverview)
  - [cleanLFP](#cleanlfp)
  - [findBadChans](#findbadchans)
  - [findBadTrials](#findbadtrials)
  - [newRef](#newref)
- [Usage Notes](#usage-notes)

---

# Installation

Clone or download this repository, and add the folder to your MATLAB path:

```matlab
addpath(genpath('path_to_lfp_preprocessing_folder'));


```


| Function         | Purpose                                                       | Key Inputs                                        | Key Outputs         |
|------------------|---------------------------------------------------------------|---------------------------------------------------|---------------------|
| `cleanLFP`       | Removes broadband noise from raw LFP using dB thresholding    | `rawLFP`, `threshold` (optional), `plotChans`     | Cleaned LFP (`data`) |
| `findBadChans`   | Detects noisy or invalid channels based on power spectra      | `data`, `freqRange`, `toplot` (optional)          | List of bad channels |
| `findBadTrials`  | Flags trials with low power or high variability               | `data`, `method` (optional), `fs`, `nfft`         | Indices of bad trials|
| `newRef`         | Re-references LFP data by median or spatial proximity  
| Function         | Purpose                                                       | Key Inputs                                        | Key Outputs         |
|------------------|---------------------------------------------------------------|---------------------------------------------------|---------------------|
| `cleanLFP`       | Removes broadband noise from raw LFP using dB thresholding    | `rawLFP`, `threshold` (optional), `plotChans`     | Cleaned LFP (`data`) |
| `findBadChans`   | Detects noisy or invalid channels based on power spectra      | `data`, `freqRange`, `toplot` (optional)          | List of bad channels |
| `findBadTrials`  | Flags trials with low power or high variability               | `data`, `method` (optional), `fs`, `nfft`         | Indices of bad trials|
| `newRef`         | Re-references LFP data by median or spatial proximity  
| Function         | Purpose                                                       | Key Inputs                                        | Key Outputs         |
|------------------|---------------------------------------------------------------|---------------------------------------------------|---------------------|
| `cleanLFP`       | Removes broadband noise from raw LFP using dB thresholding    | `rawLFP`, `threshold` (optional), `plotChans`     | Cleaned LFP (`data`) |
| `findBadChans`   | Detects noisy or invalid channels based on power spectra      | `data`, `freqRange`, `toplot` (optional)          | List of bad channels |
| `findBadTrials`  | Flags trials with low power or high variability               | `data`, `method` (optional), `fs`, `nfft`         | Indices of bad trials|
| `newRef`         | Re-references LFP data by median or spatial proximity  
| Function         | Purpose                                                       | Key Inputs                                        | Key Outputs         |
|------------------|---------------------------------------------------------------|---------------------------------------------------|---------------------|
| `cleanLFP`       | Removes broadband noise from raw LFP using dB thresholding    | `rawLFP`, `threshold` (optional), `plotChans`     | Cleaned LFP (`data`) |
| `findBadChans`   | Detects noisy or invalid channels based on power spectra      | `data`, `freqRange`, `toplot` (optional)          | List of bad channels |
| `findBadTrials`  | Flags trials with low power or high variability               | `data`, `method` (optional), `fs`, `nfft`         | Indices of bad trials|
| `newRef`         | Re-references LFP data by median or spatial proximity  
| Function         | Purpose                                                       | Key Inputs                                        | Key Outputs         |
|------------------|---------------------------------------------------------------|---------------------------------------------------|---------------------|
| `cleanLFP`       | Removes broadband noise from raw LFP using dB thresholding    | `rawLFP`, `threshold` (optional), `plotChans`     | Cleaned LFP (`data`) |
| `findBadChans`   | Detects noisy or invalid channels based on power spectra      | `data`, `freqRange`, `toplot` (optional)          | List of bad channels |
| `findBadTrials`  | Flags trials with low power or high variability               | `data`, `method` (optional), `fs`, `nfft`         | Indices of bad trials|
| `newRef`         | Re-references LFP data by median or spatial proximity  
| Function         | Purpose                                                       | Key Inputs                                        | Key Outputs         |
|------------------|---------------------------------------------------------------|---------------------------------------------------|---------------------|
| `cleanLFP`       | Removes broadband noise from raw LFP using dB thresholding    | `rawLFP`, `threshold` (optional), `plotChans`     | Cleaned LFP (`data`) |
| `findBadChans`   | Detects noisy or invalid channels based on power spectra      | `data`, `freqRange`, `toplot` (optional)          | List of bad channels |
| `findBadTrials`  | Flags trials with low power or high variability               | `data`, `method` (optional), `fs`, `nfft`         | Indices of bad trials|
| `newRef`         | Re-references LFP data by median or spatial proximity  
| Function         | Purpose                                                       | Key Inputs                                        | Key Outputs         |
|------------------|---------------------------------------------------------------|---------------------------------------------------|---------------------|
| `cleanLFP`       | Removes broadband noise from raw LFP using dB thresholding    | `rawLFP`, `threshold` (optional), `plotChans`     | Cleaned LFP (`data`) |
| `findBadChans`   | Detects noisy or invalid channels based on power spectra      | `data`, `freqRange`, `toplot` (optional)          | List of bad channels |
| `findBadTrials`  | Flags trials with low power or high variability               | `data`, `method` (optional), `fs`, `nfft`         | Indices of bad trials|
| `newRef`         | Re-references LFP data by median or spatial proximity  





---

# [FunctionOverview](functionoverview)

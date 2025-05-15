# Automated LFP Cleaning and Processing

This package provides functions for cleaning and modular referencing local field potential (LFP) recordings.

It is designed to work with both raw and epoched LFP data stored as 3D arrays (channels × time × trials) and supports common preprocessing operations such as broadband noise removal, bad trial/channel detection, and flexible re-referencing.

## Table of Contents
- [Installation](#installation)
- [Function Overview (Summary Table)](#function-overview-summary-table)
  - [cleanLFP()](#cleanlfp)
  - [findBadChans()](#findbadchans)
  - [findBadTrials()](#findbadtrials)
  - [newRef()](#newref)
- [Usage Notes](#usage-notes)

---

## Installation


1. Download and uncompress into your working directory.

2. [Cleaning functions](https://github.com/jasonnan2/Automated_LFP_Analysis/tree/main/cleaningLFPfunctions)

3. [Rereferencing Function](https://github.com/jasonnan2/Automated_LFP_Analysis/blob/main/functions/newRef.m)

## Function Overview (Summary Table)

| Function        | Purpose                                                      | Key Inputs (optional → \*)                               | Key Outputs                  |
| --------------- | ------------------------------------------------------------ | -------------------------------------------------------- | ---------------------------- |
| `cleanLFP`      | Remove broadband noise by thresholding Welch power           | `threshold*`, `plotChans*`, `fs*`, `nfft*`, `freqRange*` | cleaned LFP (`data`)         |
| `findBadChans`  | Flag noisy / invalid channels via spectral outlier detection | `freqRange`, `toplot*`, `fs*`                            | channel indices (`outliers`) |
| `findBadTrials` | Flag low-power / high-variance trials                        | `method*`, `fs*`, `nfft*`                                | trial indices (`badTrials`)  |
| `newRef`        | Re-reference data (global median, per-shank, closest, etc.)  | `refType`, `chans`                                       | re-ref. data, fallback count |

## cleanLFP

Removes broadband noise from raw LFP recordings by detecting high-power segments across all channels using a Welch-based estimate in the 1–250 Hz range.
```matlab

data = cleanLFP(rawLFP,               ... % required
                threshold,            ... % dB (default 10)
                plotChans,            ... % true / false (default false)
                fs,                   ... % Hz (default 1000)
                nfft,                 ... % Welch FFT length (default 2^⌊log2(fs/2)⌋)
                freqRange)                % [fMin fMax] Hz (default [1 250])
```

**Inputs**

| Name        | Type / Default                | Description                                |
| ----------- | ----------------------------- | ------------------------------------------ |
| `rawLFP`    | `[ch × time]`                 | Raw LFP data (double / single)             |
| `threshold` | `scalar` / **10**             | dB threshold for broadband-noise detection |
| `plotChans` | `logical` / **false**         | Plot raw (red) vs cleaned (blue) traces    |
| `fs`        | `scalar` / **1000**           | Sampling rate (Hz)                         |
| `nfft`      | `scalar` / **2^⌊log2(fs/2)⌋** | FFT length for `pwelch`                    |
| `freqRange` | `1×2 vector` / **\[1 250]**   | Frequency band used for power averaging    |


**Output**

| Name   | Type                        | Description                                       |
| ------ | --------------------------- | ------------------------------------------------- |
| `data` | `[nChannels × nTimepoints]` | Cleaned LFP with noisy segments replaced by `NaN` |


## findBadChans

Identifies noisy channels based on spectral power outliers.
```matlab

outliers = findBadChans(data,          ... % required
                        freqRange,     ... % [fMin fMax]
                        toplot,        ... % true / false (default false)
                        fs)                % Hz (default 1000)
```
                        
**Inputs**

| Name        | Type / Default        | Description                     |
| ----------- | --------------------- | ------------------------------- |
| `data`      | `[ch × time × tr]`    | Epoched LFP                     |
| `freqRange` | `1×2 vector` / **\[1 250]**         | Analysis band (e.g., `[1 250]`) |
| `toplot`    | `logical` / **false** | Plot PSDs & highlight outliers  |
| `fs`        | `scalar` / **1000**   | Sampling rate for Welch         |

**Output**

| Name       | Description                       |
| ---------- | --------------------------------- |
| `outliers` | Row vector of bad-channel indices |



## findBadTrials

Flags trials with inadequate power or abnormal variability.
```matlab

badTrials = findBadTrials(data,   ... % required
                          method, ... % 'median', 'mean', etc. (default 'median')
                          fs,     ... % Hz (default 1000)
                          nfft)       % FFT length (default 2^⌊log2(fs/2)⌋)
```


**Inputs**
| Name     | Type                   | Description                                                          |
| -------- | ---------------------- | -------------------------------------------------------------------- |
| `data`   | `[ch × time × trials]` | Epoched LFP array.                                                   |
| `method` | `char` *(optional)*    | `isoutlier` method (`'median'`, `'mean'`, etc.; default = 'median'). |
| `fs`     | `scalar` *(optional)*  | Sampling rate in Hz (default = 1000).                                |
| `nfft`   | `scalar` *(optional)*  | FFT length for Welch (default = largest power-of-2 ≤ `fs/2`).        |

**Output**
| Name        | Type     | Description                            |
| ----------- | -------- | -------------------------------------- |
| `badTrials` | `vector` | Indices of trials marked as artifacts. |


## newRef

Re-references LFP data using global or spatially informed strategies.
```matlab
[refData, nFallback] = newRef(sessionData, refType, chans)
```

**Inputs**
| Name          | Type                                    | Description                                                          |
| ------------- | --------------------------------------- | -------------------------------------------------------------------- |
| `sessionData` | `[ch × time × trials]` or `[ch × time]` | Raw or epoched LFP.                                                  |
| `refType`     | `char`                                  | `'none'`, `'median'`, `'shank'`, `'closest'`, or `'ClosestInShank'`. |
| `chans`       | `table`                                 | Channel metadata with `grouping`, `x`, `y`, `z` columns. (anatomical coordinates)             |

### Sample `chans` Table for `newRef`

| Name   | grouping | AP | ML  | DV  |
|--------|----------|----|-----|-----|
| N Ac sh| 1        | 2  | 0.6 | 6.6 |
| A33    | 1        | 2  | 0.6 | 3.5 |
| A24a   | 1        | 2  | 0.6 | 3.0 |



**Output**
| Name             | Type                   | Description                                                          |
| ---------------- | ---------------------- | -------------------------------------------------------------------- |
| `referencedData` | *(same size as input)* | Re-referenced LFP data.                                              |
| `count`          | `scalar`               | # channels that fell back to global reference when local one failed. |



## Usage Notes
```matlab
% --- cleaning LFP ---
cln = cleanLFP(rawLFP, 10);

% --- channel QC ---
badCh  = findBadChans(reshape(cln,32,[],nTrials), [1 250]);

% --- trial QC ---
badTrl = findBadTrials(reshape(cln,32,[],nTrials));

% --- re-reference ---
[refData, nFallback] = newRef(reshape(cln,32,[],nTrials), 'shank', chanTbl);
```

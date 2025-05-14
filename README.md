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
...

## cleanLFP

Removes broadband noise from raw LFP recordings by detecting high-power segments across all channels using a Welch-based estimate in the 1–250 Hz range.


**Inputs**

| Name        | Type                        | Description                                                    |
| ----------- | --------------------------- | -------------------------------------------------------------- |
| `rawLFP`    | `[nChannels × nTimepoints]` | Raw LFP data matrix                                            |
| `threshold` | `scalar` *(optional)*       | Power threshold in decibels (default = 10)                     |
| `plotChans` | `bool` *(optional)*         | Plot raw vs. cleaned signal for each channel (default = false) |

**Outputs**

| Name   | Type                        | Description                                       |
| ------ | --------------------------- | ------------------------------------------------- |
| `data` | `[nChannels × nTimepoints]` | Cleaned LFP with noisy segments replaced by `NaN` |


## findBadChans

Identifies noisy channels based on spectral power outliers.






## findBadTrials

Flags trials with inadequate power or abnormal variability.

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

**Inputs**
| Name          | Type                                    | Description                                                          |
| ------------- | --------------------------------------- | -------------------------------------------------------------------- |
| `sessionData` | `[ch × time × trials]` or `[ch × time]` | Raw or epoched LFP.                                                  |
| `refType`     | `char`                                  | `'none'`, `'median'`, `'shank'`, `'closest'`, or `'ClosestInShank'`. |
| `chans`       | `table`                                 | Channel metadata with `grouping`, `x`, `y`, `z` columns. (anatomical coordinates)             |

**Output**
| Name             | Type                   | Description                                                          |
| ---------------- | ---------------------- | -------------------------------------------------------------------- |
| `referencedData` | *(same size as input)* | Re-referenced LFP data.                                              |
| `count`          | `scalar`               | # channels that fell back to global reference when local one failed. |



## Usage Notes

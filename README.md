# PLEKHA1 Bulk RNA-seq Analysis

Alignment pipeline for PLEKHA1 bulk RNA-seq using GENCODE v46 and GRCh38.p14.

## Overview

This pipeline performs STAR alignment on 19 bulk RNA-seq samples for PLEKHA1 isoform analysis.

## Scripts

### 1. Build STAR Index
**File:** `32_build_star_index_v46.sbatch`

Builds STAR index using GENCODE v46 annotations and GRCh38.p14 genome with STAR 2.7.10a.

**Usage:**
```bash
sbatch 32_build_star_index_v46.sbatch
```

**Runtime:** ~3-4 hours  
**Resources:** 16 CPUs, 48GB RAM

### 2. Align Reads
**File:** `31_align_star_v46.sbatch`

Aligns paired-end RNA-seq reads using STAR, outputs sorted and indexed BAM files.

**Usage:**
```bash
# Test with one sample
sbatch --array=1 31_align_star_v46.sbatch

# Run all 19 samples (8 concurrent jobs)
sbatch --array=1-19%8 31_align_star_v46.sbatch
```

**Runtime:** ~7-9 minutes per sample  
**Resources:** 12 CPUs, 48GB RAM per job

## Requirements

- STAR 2.7.10a
- samtools 1.15.1
- Access to shared GENCODE v46 annotations: `/share/crsp/lab/alaspada/share/disk1/LaSpada/plekha1_bulkseq/gencode46_grch38p14_annotation/`

## Sample Information

19 samples listed in `metadata/bulk_srr_accessions.txt`

## Sample Metadata

**File:** `metadata/sample_metadata.tsv`

Sample metadata includes:
- **19 samples**: 11 AD cases, 8 controls
- **Columns**: SRR ID, sample number, diagnosis (AD/Control), GSM accession

**Library Information:**
- **Strandedness**: Reverse-stranded (use column 3 from STAR ReadsPerGene.out.tab or `-s 2` for featureCounts)
- **Layout**: Paired-end (100bp or 150bp)
- **Platform**: Illumina

**Note:** Current metadata is minimal (diagnosis only). Missing standard confounders (age, sex, PMI, batch, etc.).

## Output

- **STAR Index:** `star_index_v46/`
- **BAM files:** `aligned_v46/`
- **Logs:** `logs/`

## Workflow

1. Build STAR index (run once)
2. Wait for index build to complete
3. Run alignment on all samples
4. BAM files will be sorted by coordinate and indexed

## Notes

- BAM files are temporarily written to local `aligned_v46/` directory
- Once permissions are fixed, can be moved to shared folder for downstream analysis
- This pipeline was developed using GitHub Copilot on VS Code

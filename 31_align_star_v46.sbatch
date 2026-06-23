#!/bin/bash
#SBATCH --job-name=star_v46_align
#SBATCH -A alaspada_lab
#SBATCH -p standard
#SBATCH --nodes=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=48G
#SBATCH --time=8:00:00
#SBATCH --constraint=fastscratch
#SBATCH --output=logs/star_v46_align_%A_%a.out
#SBATCH --error=logs/star_v46_align_%A_%a.err

set -euo pipefail

echo "=================================================="
echo "STAR alignment using GENCODE v46 index"
echo "Job ID: ${SLURM_JOB_ID}"
echo "Array Task ID: ${SLURM_ARRAY_TASK_ID}"
echo "Node: $(hostname)"
echo "Started: $(date)"
echo "=================================================="

# Load STAR and samtools
module purge
module load star/2.7.10a
module load samtools/1.15.1

# Set up paths
PROJECT_ROOT="${PROJECT_ROOT:-$SLURM_SUBMIT_DIR}"
cd "$PROJECT_ROOT"

# Paths
STAR_INDEX="star_index_v46"
# Output to local directory (temporary - will copy to shared folder once permissions are fixed)
OUTPUT_BASE="aligned_v46"
mkdir -p "$OUTPUT_BASE"

# Get the SRR accession for this array task
SRR="$(sed -n "${SLURM_ARRAY_TASK_ID}p" metadata/bulk_srr_accessions.txt)"
if [[ -z "${SRR}" ]]; then
  echo "ERROR: No SRR found for array task ${SLURM_ARRAY_TASK_ID}" >&2
  exit 2
fi

echo "Processing: ${SRR}"
echo "Threads: ${SLURM_CPUS_PER_TASK}"
echo "STAR Index: ${STAR_INDEX}"
echo "Output Directory: ${OUTPUT_BASE}"
echo ""

# Input FASTQ files (from your current project)
R1="fastq/${SRR}_1.fastq.gz"
R2="fastq/${SRR}_2.fastq.gz"

# Verify input files exist
if [[ ! -f "$R1" || ! -f "$R2" ]]; then
  echo "ERROR: FASTQ files not found for ${SRR}" >&2
  echo "  Expected: $R1" >&2
  echo "  Expected: $R2" >&2
  exit 1
fi

echo "=== Input files ==="
ls -lh "$R1" "$R2"
echo ""

# Verify STAR index exists
if [[ ! -d "$STAR_INDEX" ]]; then
  echo "ERROR: STAR index not found at ${STAR_INDEX}" >&2
  exit 1
fi

echo "=== Running STAR alignment ==="
STAR \
  --runThreadN ${SLURM_CPUS_PER_TASK} \
  --genomeDir "$STAR_INDEX" \
  --readFilesIn "$R1" "$R2" \
  --readFilesCommand zcat \
  --outFileNamePrefix "${OUTPUT_BASE}/${SRR}." \
  --outSAMtype BAM SortedByCoordinate \
  --outSAMunmapped Within \
  --outSAMattributes Standard \
  --quantMode GeneCounts \
  --limitBAMsortRAM 40000000000

echo ""
echo "=== Indexing BAM file ==="
samtools index "${OUTPUT_BASE}/${SRR}.Aligned.sortedByCoord.out.bam"

echo ""
echo "=== Alignment statistics ==="
cat "${OUTPUT_BASE}/${SRR}.Log.final.out"

echo ""
echo "=== Gene counts preview ==="
echo "First 10 genes:"
head -n 14 "${OUTPUT_BASE}/${SRR}.ReadsPerGene.out.tab"

echo ""
echo "=== Output files ==="
ls -lh "${OUTPUT_BASE}/${SRR}."*

echo ""
echo "=================================================="
echo "Completed: ${SRR}"
echo "Finished: $(date)"
echo "=================================================="

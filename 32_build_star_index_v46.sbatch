#!/bin/bash
#SBATCH --job-name=star_index_v46
#SBATCH -A alaspada_lab
#SBATCH -p standard
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=48G
#SBATCH --time=4:00:00
#SBATCH --output=logs/star_index_v46_%j.out
#SBATCH --error=logs/star_index_v46_%j.err

set -euo pipefail

echo "=================================================="
echo "Building STAR index for GENCODE v46 GRCh38.p14"
echo "Job ID: ${SLURM_JOB_ID}"
echo "Node: $(hostname)"
echo "Started: $(date)"
echo "=================================================="

# Load STAR
module purge
module load star/2.7.10a

echo ""
echo "STAR version:"
STAR --version

# Set up paths
PROJECT_ROOT="${PROJECT_ROOT:-$SLURM_SUBMIT_DIR}"
cd "$PROJECT_ROOT"

SHARED_FOLDER="/share/crsp/lab/alaspada/share/disk1/LaSpada/plekha1_bulkseq/gencode46_grch38p14_annotation"
GENOME_FASTA="${SHARED_FOLDER}/GRCh38.primary_assembly.genome.fa"
GTF_FILE="${SHARED_FOLDER}/gencode.v46.primary_assembly.annotation.gtf"
OUTPUT_DIR="star_index_v46"

# Verify input files exist
if [[ ! -f "$GENOME_FASTA" ]]; then
  echo "ERROR: Genome FASTA not found at ${GENOME_FASTA}" >&2
  exit 1
fi

if [[ ! -f "$GTF_FILE" ]]; then
  echo "ERROR: GTF file not found at ${GTF_FILE}" >&2
  exit 1
fi

echo ""
echo "=== Input files ==="
echo "Genome FASTA: ${GENOME_FASTA}"
ls -lh "$GENOME_FASTA"
echo ""
echo "GTF file: ${GTF_FILE}"
ls -lh "$GTF_FILE"

echo ""
echo "=== Building STAR index ==="
echo "Output directory: ${OUTPUT_DIR}/"
echo "Threads: ${SLURM_CPUS_PER_TASK}"
echo ""

mkdir -p "$OUTPUT_DIR"

STAR \
  --runMode genomeGenerate \
  --runThreadN ${SLURM_CPUS_PER_TASK} \
  --genomeDir "$OUTPUT_DIR" \
  --genomeFastaFiles "$GENOME_FASTA" \
  --sjdbGTFfile "$GTF_FILE" \
  --sjdbOverhang 100 \
  --genomeSAindexNbases 14

echo ""
echo "=== Index build complete ==="
ls -lh "${OUTPUT_DIR}/"

echo ""
echo "=== Verification ==="
echo "Genome parameters:"
cat "${OUTPUT_DIR}/genomeParameters.txt"

echo ""
echo "=================================================="
echo "STAR index ready!"
echo "Index location: ${OUTPUT_DIR}/"
echo "Next step: Update 31_align_star_v46.sbatch to use this index"
echo "Finished: $(date)"
echo "=================================================="

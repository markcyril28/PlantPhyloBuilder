#!/bin/bash

input_group="curated_21_genes_version"

mkdir -p logs
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TIME_LOG="logs/phylo_pipeline_${TIMESTAMP}_${input_group}_script_time_log.log"

# Run with timing
/usr/bin/time -v bash generate_Alignment_and_Phylo.sh --group "$input_group" 2>> "$TIME_LOG"

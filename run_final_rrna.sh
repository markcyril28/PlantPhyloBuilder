#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/1_CONFIG_FILES/space_time.sh"

setup_logging

input_group="Final_Curated_Set"

log_step "Starting rRNA/18S Pipeline for $input_group"

# Process only rRNA/18S sequences
run_with_space_time_log \
    bash generate_Alignment_and_Phylo.sh --group "$input_group" \
    --rna --alignment TRUE --phylo TRUE

log_step "rRNA/18S Pipeline Completed"

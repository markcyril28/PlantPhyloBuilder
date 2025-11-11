#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/1_CONFIG_FILES/space_time.sh"

setup_logging

input_group="Final_Curated_Set"

log_step "Starting matK Pipeline for $input_group"

# Process only matK sequences
run_with_space_time_log \
    bash generate_Alignment_and_Phylo.sh --group "$input_group" \
    --matk --alignment FALSE --phylo TRUE

log_step "matK Pipeline Completed"

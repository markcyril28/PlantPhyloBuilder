#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/1_CONFIG_FILES/space_time.sh"

setup_logging

log_step "Starting Complete Pipeline - All Sequence Types"

bash run_final_matk.sh 

bash run_final_rrna.sh

bash run_final_concatenated.sh

log_step "Complete Pipeline Finished"

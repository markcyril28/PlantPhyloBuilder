#!/bin/bash

# Define an array of folder names
folders=(
  0_INPUT_RAW_FASTA_and_ALIGNMENT
  1_CONFIG_FILES
  2_OUTPUT_TREES
)

# Create each folder if it does not exist
for folder in ${folders[@]}; do
  mkdir -p "$folder"
done

megacc \
  -a 1_CONFIG_FILES/infer_ML_nucleotide_TEST.mao \
  -d 0_INPUT_RAW_FASTA_and_ALIGNMENT/test_data.fas \
  -o Nucleotide_ML_tree_1000.nwks

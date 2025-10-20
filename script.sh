#!/bin/bash

# Define an array of folder names
folders=(

  "04_Multiple_Sequence_Alignment"
  "05_Phylogenetic_Analysis"

)

# Create each folder if it does not exist
for folder in ${folders[@]}; do
  mkdir -p "$folder"
done

megacc -a infer_ML_nucleotide_TEST.mao -d test_data.fas -o JRO_ML_tree_1000.nwks

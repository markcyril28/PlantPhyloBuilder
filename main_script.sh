#!/bin/bash

# Define an array of folder names
folders=(
  "00_Raw_Data"
  "01_Quality_Control"
  "02_Trimming"
  "03_BLAST"
  "04_Multiple_Sequence_Alignment"
  "05_Phylogenetic_Analysis"
  "06_Protein_Modeling"
)

# Create each folder if it does not exist
for folder in ${folders[@]}; do
  mkdir -p "$folder"
done

megacc -a infer_ML_nucleotide.mao -d test_data.fas -o JRO_ML_tree_1000.nwks

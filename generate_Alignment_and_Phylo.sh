#!/bin/bash
#set -euo pipefail

# ========================================
# Phylogenetic Analysis Pipeline
# ========================================
# Performs phylogenetic analysis.
# 1. Discovers and merges FASTA files from query directories
# 2. Performs multiple sequence alignment (MUSCLE, CLUSTAL, MAFFT, PROBCONS)
# 3. Constructs phylogenetic trees using MEGACC/IQTREE2
#
# Dependencies: MUSCLE, ClustalW, MAFFT, PROBCONS, MEGACC, IQ-TREE2
# ========================================

# ---------------- INPUTS ----------------
readonly INPUT_BASE_DIR="$PWD"
readonly INPUT_DIR="0_INPUT_RAW_FASTA_and_ALIGNMENT"
readonly CONFIG_DIR="1_CONFIG_FILES"

mkdir -p "$INPUT_DIR/b_RAW" "$CONFIG_DIR" 

INPUT_GROUP=(
    #"f_Curated"
    #"64_genes_version"
    "21_lifted_genes_version"
    #"curated_21_genes_version"
)

# Alignment methods to use
readonly ALIGNMENT_METHODS=(
    "CLUSTAL"
    #"MAFFT"
    #"PROBCONS"
    #"MUSCLE"
    #"T_COFFEE_Default"
    #"T_COFFEE_Expresso"
    #"T_COFFEE_PsiCoffee"
    #"T_COFFEE_Consensus"
)

# Phylogenetic software to use
readonly PHYLO_SOFTWARE=(
    "MEGA_CC_12_Ubuntu"
    "IQTREE2"
)

readonly CONFIG_FILE=(
	"$CONFIG_DIR/infer_ML_nucleotide.mao"
    #"$CONFIG_DIR/infer_ML_amino_acid.mao"
)

CPU=4           # Optimal Number of CPU cores to use    
RUN_ALIGNMENT=FALSE
RUN_PHYLO=TRUE


# ---------------- OUTPUTS ----------------
readonly OUTPUT_DIR="2_PHYLOGENETIC_TREE_RESULTS"

# ========================================================================
# LOGGING
# ========================================================================
RUN_ID="${RUN_ID:-$(date +%Y%m%d_%H%M%S)}"
LOG_DIR="${LOG_DIR:-logs}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/phylo_pipeline_${RUN_ID}_full_log.log}"
rm -rf "logs.log"

timestamp() { date '+%Y-%m-%d %H:%M:%S'; }
log() { local level="$1"; shift; printf '[%s] [%s] %s\n' "$(timestamp)" "$level" "$*"; }
log_info() { log INFO "$@"; }
log_warn() { log WARN "$@"; }
log_error() { log ERROR "$@"; }
log_step() { log INFO "============================== $* =============================="; }

setup_logging() {
	mkdir -p "$LOG_DIR"
    
	log_choice="${log_choice:-1}"
	if [[ "$log_choice" == "2" ]]; then
		exec >"$LOG_FILE" 2>&1
	else
		exec > >(tee -a "$LOG_FILE") 2>&1
	fi
	log_info "Log: $LOG_FILE"
}

trap 'log_error "Command failed (rc=$?) at line $LINENO: ${BASH_COMMAND:-unknown}"; exit 1' ERR
trap 'log_info "Finished"' EXIT

run_with_time_to_log() {
	/usr/bin/time -v "$@" >> "$LOG_FILE" 2>&1
}

# ========================================================================
# FUNCTIONS
# ========================================================================

validate_fasta_sequences() {
    local file=$1
    local has_valid_sequence=false
    local current_header=""
    local current_sequence=""
    local line_count=0
    
    while IFS= read -r line; do
        ((line_count++))
        [[ -z "$line" ]] && continue
        if [[ "$line" =~ ^">" ]]; then
            if [[ -n "$current_header" ]]; then
                local clean_sequence=$(echo "$current_sequence" | tr -d '[:space:]')
                if [[ -n "$clean_sequence" ]]; then
                    has_valid_sequence=true; break
                fi
            fi
            current_header="$line"; current_sequence=""
        else
            current_sequence+="$line"
        fi
    done < "$file"
    
    if [[ -n "$current_header" ]]; then
        local clean_sequence=$(echo "$current_sequence" | tr -d '[:space:]')
        if [[ -n "$clean_sequence" ]]; then
            has_valid_sequence=true
        fi
    fi
    
    if [[ $line_count -eq 0 ]]; then
        log_warn "Empty: $file"
        return 1
    fi
    $has_valid_sequence
}

clean_merged_fasta() {
    local input_file=$1
    local temp_file="${input_file}.tmp"
    local current_header=""
    local current_sequence=""
    local entries_removed=0
    
    > "$temp_file"
    while IFS= read -r line; do
        if [[ "$line" =~ ^">" ]]; then
            if [[ -n "$current_header" ]]; then
                local clean_sequence=$(echo "$current_sequence" | tr -d '[:space:]')
                if [[ -n "$clean_sequence" ]]; then
                    echo "$current_header" >> "$temp_file"
                    echo "$current_sequence" >> "$temp_file"
                else
                    ((entries_removed++))
                fi
            fi
            current_header="$line"; current_sequence=""
        else
            current_sequence+="$line"$'\n'
        fi
    done < "$input_file"
    
    if [[ -n "$current_header" ]]; then
        local clean_sequence=$(echo "$current_sequence" | tr -d '[:space:]')
        if [[ -n "$clean_sequence" ]]; then
            echo "$current_header" >> "$temp_file"
            echo "$current_sequence" >> "$temp_file"
        else
            ((entries_removed++))
        fi
    fi
    
    mv "$temp_file" "$input_file"
    [[ $entries_removed -gt 0 ]] && log_info "Cleaned: removed $entries_removed empty sequences"
}

merge_fasta_by_gene() {
    local query_dir=$1; local prefix=$2; local gene_type=$3; local output_dir="$4"
    local output_file="$output_dir/${prefix}_Smel_${gene_type}_merged.fasta"
    [[ ! -d "$query_dir" ]] && { log_error "Directory not found: $query_dir"; return 1; }
    
    if [[ -s "$output_file" ]]; then
        log_info "$gene_type merge: SKIPPED (exists)"
        return 0
    fi
    log_step "Merging $gene_type"
    
    > "$output_file"
    local count=0
    while IFS= read -r -d '' file; do
        local filename=$(basename "$file")
        if [[ "$filename" == *"$gene_type"* ]]; then
            if [[ -s "$file" ]]; then
                if validate_fasta_sequences "$file"; then
                    [[ $count -gt 0 ]] && echo "" >> "$output_file"
                    cat "$file" >> "$output_file" && ((count++))
                fi
            fi
        fi
    done < <(find "$query_dir" -type f \( -iname "*.fa" -o -iname "*.fasta" \) -print0)
    
    log_info "Merged $count files"
    [[ -s "$output_file" ]] && clean_merged_fasta "$output_file"
}

align_sequences() {
    local input_file=$1; local method=$2; local output_dir=$3
    local basename=$(basename "$input_file" .fasta)
    local output_file="$output_dir/${basename}.fas"
    
    [[ ! -s "$input_file" ]] && { log_warn "Empty input: $input_file"; return 1; }
    if [[ -s "$output_file" ]]; then
        log_info "Align $method: SKIPPED (exists)"
        return 0
    fi

    log_step "Aligning $basename with $method"
    case "$method" in
        "MUSCLE") 
            muscle -in "$input_file" -out "$output_file" -maxiters 1000 -diags0 -threads $CPU ;;
        
        "CLUSTAL") 
            clustalo -i "$input_file" -o "$output_file" --outfmt=fasta \
                --full --full-iter --iter=1000 \
                --max-guidetree-iterations=1000 --max-hmm-iterations=1000 \
                --threads $CPU ;;
        
        "MAFFT") 
            mafft --thread $CPU --localpair --maxiterate 1000 "$input_file" > "$output_file" ;;
        
        "PROBCONS") 
            probcons -c 5 -ir 1000 -pre 20 "$input_file" > "$output_file" ;;
        
        "T_COFFEE_Expresso") 
            t_coffee -seq "$input_file" -method expresso \
                -output=fasta_aln -outfile "$output_file" -cpu=$CPU ;;

        "T_COFFEE_PsiCoffee") 
            t_coffee -seq "$input_file" -profile "$HMM_profile_aln_file" \
                -outfile "$output_file" -output=fasta_aln \
                -cpu=$CPU -iterate 1000 ;;
        
        "T_COFFEE_Consensus")
            t_coffee -seq "$input_file" \
                -output=fasta_aln \
                -outfile "$output_file" \
                -method mafft_msa,clustalw_msa,muscle_msa,probcons_msa \
                -n_core=$CPU -mode accurate -quiet ;;
        *) 
            log_error "Unknown alignment method: $method"; return 1 ;;
    esac

    log_info "Output alignment: $output_file"
}

generate_MEGA_CC_12_Ubuntu_tree() {
    local aligned_file=$1
    local method=$2
    local config_file=$3
    local output_dir=$4

    local basename=$(basename "$aligned_file" .fas)
    local config_base=$(basename "$config_file" .mao)
    local tree_dir="$output_dir/${method}_aligned/MEGA12_Ubuntu"
    local output_file="$tree_dir/${basename}_${config_base}.nwk"
    local mega_log="$tree_dir/${basename}_MEGA.log"

    mkdir -p "$tree_dir"
    touch "$mega_log"

    # Pre-checks
    if [[ ! -s "$aligned_file" ]]; then
        log_warn "Aligned file empty: $aligned_file"
        return 1
    fi
    if [[ ! -f "$config_file" ]]; then
        log_error "Config file not found: $config_file"
        return 1
    fi

    # Skip if already generated
    if [[ -s "$output_file" ]]; then
        log_info "Tree already exists: $output_file (skipped)"
        return 0
    fi

    log_info "Generating MEGA tree for $(basename "$aligned_file") | Aligned with $method | Config: $(basename "$config_file")"

    # Run MEGA with timing and log output
    megacc \
        -d "$aligned_file" \
        -a "$config_file" \
        -o "$output_file" \
        --cpu $CPU \
        > "$mega_log" 2>&1

    if [[ -s "$output_file" ]]; then
        log_info "✅ Tree: $output_file"
    else
        log_error "MEGA12 failed (see $mega_log)"
        return 1
    fi
}


generate_IQTREE2_tree() {
    local aligned_file=$1
    local method=$2
    local output_dir=$3

    local basename=$(basename "$aligned_file" .fas)
    local tree_dir="$output_dir/${method}_aligned/IQTREE2"
    local output_prefix="$tree_dir/${basename}_IQTREE2"
    local tree_file="${output_prefix}.treefile"
    local log_file="${output_prefix}.log"

    mkdir -p "$tree_dir"
    touch "$log_file"

    # Pre-checks
    if [[ ! -s "$aligned_file" ]]; then
        log_warn "Empty: $aligned_file"
        return 1
    fi
    if ! command -v iqtree &>/dev/null; then
        log_error "iqtree not in PATH"
        return 1
    fi

    # Skip if already generated
    if [[ -s "$tree_file" ]]; then
        log_info "IQ-TREE2: SKIPPED (exists)"
        return 0
    fi

    log_step "IQ-TREE2: $basename | $method"

    # Run IQ-TREE2 with timing and bootstrap support
    iqtree \
        -s "$aligned_file" \
        -nt AUTO \
        -bb 2000 \
        -alrt 1000 \
        -pre "$output_prefix" \
        > "$log_file" 2>&1

    if [[ -s "$tree_file" ]]; then
        log_info "✅ Tree: $tree_file"
    else
        log_error "IQ-TREE2 failed (see $log_file)"
        return 1
    fi
}


# (Tree generation functions updated similarly: replace echo with log_info/log_error)

# ========================================================================
# MAIN
# ========================================================================
main() {
    setup_logging
    log_step "Starting Phylogenetic Analysis Pipeline"

    for group in "${INPUT_GROUP[@]}"; do
        local query_dir="$INPUT_DIR/$group"
        local output_subdir="$OUTPUT_DIR/$group"
        mkdir -p "$query_dir/b_RAW" "$output_subdir"

        if [ "$RUN_ALIGNMENT" = TRUE ]; then
            log_step "Step 2: Sequence Alignments for $group"
            for b_RAW_file in "$query_dir/b_RAW/"*.fasta; do
                [[ ! -f "$b_RAW_file" ]] && continue
                for align_method in "${ALIGNMENT_METHODS[@]}"; do
                    mkdir -p "$query_dir/c_ALIGNMENT/${align_method}_aligned"
                    align_sequences "$b_RAW_file" "$align_method" "$query_dir/c_ALIGNMENT/${align_method}_aligned"
                done
            done
        else
            log_warn "Skipping alignment (RUN_ALIGNMENT=FALSE)"
        fi

        if [ "$RUN_PHYLO" = TRUE ]; then
    log_step "Step 3: Phylogenetic Trees for $group"

    for align_method in "${ALIGNMENT_METHODS[@]}"; do
        aligned_files=("$query_dir/c_ALIGNMENT/${align_method}_aligned/"*.fas)
        for aligned_file in "${aligned_files[@]}"; do
            [[ ! -f "$aligned_file" ]] && continue
            
            config_file="$CONFIG_DIR/infer_ML_nucleotide.mao"

            for software in "${PHYLO_SOFTWARE[@]}"; do

                case "$software" in

                    "MEGA_CC_12_Ubuntu")
                        log_step "$software"
                        generate_MEGA_CC_12_Ubuntu_tree "$aligned_file" "$align_method" "$config_file" "$output_subdir"
                        ;;

                    "IQTREE2")
                        log_step "$software"
                        generate_IQTREE2_tree "$aligned_file" "$align_method" "$output_subdir"
                        ;;
                    *)
                        log_error "Unknown software: $software"
                        ;;
                esac
            done
        done
    done

else
    log_warn "Skipping phylogenetic tree generation (RUN_PHYLO=FALSE)"
fi

    done

    log_step "Pipeline Completed"
}

main "$@"

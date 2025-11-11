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
#
# Logging: All alignment and phylogenetic tree generation commands use 
# run_with_space_time_log for comprehensive time/space metrics tracking.
# ========================================

# Source logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/1_CONFIG_FILES/space_time.sh"

# ---------------- INPUTS ----------------
readonly INPUT_BASE_DIR="$PWD"
readonly INPUT_DIR="0_INPUT_RAW_FASTA_and_ALIGNMENT"
readonly CONFIG_DIR="1_CONFIG_FILES"

mkdir -p "$INPUT_DIR" "$CONFIG_DIR" 

INPUT_GROUP=(
    #"64_genes_version"
    #"21_lifted_genes_version"
    #"curated_21_genes_version"
    #"curated_64_genes_version"
)

# Accept from CLI; if none provided, we'll use the list above.
# If that list is empty, we'll auto-discover later.

# Accept from CLI or auto-discover later if empty
#INPUT_GROUP=()

# Alignment methods to use
readonly ALIGNMENT_METHODS=(
    #"CLUSTALO"
    "CLUSTALW"
    #"MAFFT"
    #"PROBCONS"
    #"MUSCLE"
)

# Phylogenetic software to use
readonly PHYLO_SOFTWARE=(
    "MEGA_CC_12_Ubuntu"
    "IQTREE2"
)

readonly CONFIG_FILE=(
	"$CONFIG_DIR/infer_ML_nucleotide_18s.mao"
    "$CONFIG_DIR/infer_ML_nucleotide_matK_and_concat.mao"
    #"$CONFIG_DIR/infer_ML_amino_acid.mao"
)

CPU=8               # Optimal Number of CPU cores to use for Phylo is 8  
RUN_ALIGNMENT=${RUN_ALIGNMENT:-FALSE}
RUN_PHYLO=${RUN_PHYLO:-FALSE}

# Sequence types to process (matk, rna, concat)
# Empty means all sequences; specify to filter
SEQUENCE_TYPES=()

# ---------------- OUTPUTS ----------------
readonly OUTPUT_DIR="2_PHYLOGENETIC_TREE_RESULTS"

# ========================================================================
# FUNCTIONS
# ========================================================================

print_usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -g, --group NAME         Add a single input group (can be repeated)
  -G, --groups LIST        Comma-separated list of groups
  --alignment TRUE|FALSE   Enable/disable alignment step
  --phylo TRUE|FALSE       Enable/disable phylogenetic tree generation
  --seq-type TYPE          Add sequence type to process (matk, rna, concat)
  --matk                   Process only matK sequences
  --rna                    Process only rRNA/18S sequences
  --concat                 Process only concatenated sequences
  -h, --help               Show this help

Notes:
  If no groups are provided, the script uses the INPUT_GROUP list defined near the top of the file.
  If that list is empty, it auto-discovers groups under '$INPUT_DIR' that contain a 'b_RAW' directory.
  If no sequence types are specified, all available sequences are processed.

Examples:
  $(basename "$0") --group curated_21_genes_version
  $(basename "$0") --groups curated_21_genes_version,curated_64_genes_version
  $(basename "$0") --group 21_lifted_genes_version --matk --phylo TRUE
  $(basename "$0") --group 21_lifted_genes_version --rna --alignment TRUE
  $(basename "$0") --group 21_lifted_genes_version --concat --phylo TRUE
EOF
}

parse_args() {
    local cli_specified=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -g|--group)
                [[ -n "${2:-}" ]] || { echo "Missing value for $1"; exit 2; }
                if [[ "$cli_specified" == false ]]; then
                    # First CLI group provided: override defaults
                    INPUT_GROUP=()
                    cli_specified=true
                fi
                INPUT_GROUP+=("$2"); shift 2 ;;
            -G|--groups)
                [[ -n "${2:-}" ]] || { echo "Missing value for $1"; exit 2; }
                IFS=',' read -r -a __groups <<< "$2"
                if [[ "$cli_specified" == false ]]; then
                    # First CLI groups provided: override defaults
                    INPUT_GROUP=()
                    cli_specified=true
                fi
                for g in "${__groups[@]}"; do
                    [[ -n "$g" ]] && INPUT_GROUP+=("$g")
                done
                shift 2 ;;
            --run-alignment)
                RUN_ALIGNMENT=TRUE; shift ;;
            --skip-alignment)
                RUN_ALIGNMENT=FALSE; shift ;;
            --alignment)
                [[ -n "${2:-}" ]] || { echo "Missing value for $1 (true/false)"; exit 2; }
                case "${2,,}" in
                    TRUE|true|1|yes|on) RUN_ALIGNMENT=TRUE ;;
                    FALSE|false|0|no|off) RUN_ALIGNMENT=FALSE ;;
                    *) echo "Invalid value for --alignment: $2 (use true/false)"; exit 2 ;;
                esac
                shift 2 ;;
            --run-phylo)
                RUN_PHYLO=TRUE; shift ;;
            --skip-phylo)
                RUN_PHYLO=FALSE; shift ;;
            --phylo)
                [[ -n "${2:-}" ]] || { echo "Missing value for $1 (true/false)"; exit 2; }
                case "${2,,}" in
                    TRUE|true|1|yes|on) RUN_PHYLO=TRUE ;;
                    FALSE|false|0|no|off) RUN_PHYLO=FALSE ;;
                    *) echo "Invalid value for --phylo: $2 (use true/false)"; exit 2 ;;
                esac
                shift 2 ;;
            --seq-type)
                [[ -n "${2:-}" ]] || { echo "Missing value for $1"; exit 2; }
                case "${2,,}" in
                    matk|rna|concat|concatenated)
                        local seq_type="${2,,}"
                        [[ "$seq_type" == "concatenated" ]] && seq_type="concat"
                        SEQUENCE_TYPES+=("$seq_type")
                        ;;
                    *) echo "Invalid sequence type: $2 (use matk, rna, or concat)"; exit 2 ;;
                esac
                shift 2 ;;
            --matk)
                SEQUENCE_TYPES+=("matk"); shift ;;
            --rna)
                SEQUENCE_TYPES+=("rna"); shift ;;
            --concat|--concatenated)
                SEQUENCE_TYPES+=("concat"); shift ;;
            -h|--help)
                print_usage; exit 0 ;;
            --)
                shift; break ;;
            *)
                echo "Unknown argument: $1"
                print_usage; exit 2 ;;
        esac
    done
}

format_fasta_fold_60() {
    # Format a FASTA sequence in standard 60-character lines
    local input_file=$1
    [[ ! -f "$input_file" ]] && { log_error "File not found: $input_file"; return 1; }
    
    local temp_file="${input_file}.fmt_tmp"
    : > "$temp_file"
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^">" ]]; then
            [[ -s "$temp_file" ]] && echo "" >> "$temp_file"
            echo "$line" >> "$temp_file"
        else
            echo "$line" | fold -w 60 >> "$temp_file"
        fi
    done < "$input_file"
    
    mv "$temp_file" "$input_file"
    log_info "Formatted: $input_file"
}

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
    
    : > "$temp_file"
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
    
    : > "$output_file"
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
    
    # Log space metrics for merge operation
    if [[ -s "$output_file" ]]; then
        log_file_size "$output_file" "Merged ${gene_type} sequences"
    fi
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
            run_with_space_time_log \
                --input "$input_file" \
                --output "$output_file" \
                muscle -in "$input_file" -out "$output_file" -maxiters 1000 -diags0 -threads $CPU ;;
        
        "CLUSTALO")
            run_with_space_time_log \
                --input "$input_file" \
                --output "$output_file" \
                clustalo -i "$input_file" -o "$output_file" --outfmt=fasta ;;

        "CLUSTALW")
            run_with_space_time_log \
                --input "$input_file" \
                --output "$output_file" \
                clustalw -INFILE="$input_file" -OUTFILE="$output_file" -OUTPUT=FASTA ;;
        
        "MAFFT") 
            run_with_space_time_log \
                --input "$input_file" \
                --output "$output_file" \
                bash -c "mafft --thread $CPU --localpair --maxiterate 1000 '$input_file' > '$output_file'" ;;
        
        "PROBCONS") 
            run_with_space_time_log \
                --input "$input_file" \
                --output "$output_file" \
                bash -c "probcons -c 5 -ir 1000 -pre 20 '$input_file' > '$output_file'" ;; 
        *) 
            log_error "Unknown alignment method: $method"; return 1 ;;
    esac

    log_info "Output alignment: $output_file"
    
    # Log space metrics for alignment
    if [[ -s "$output_file" ]]; then
        log_input_output_size "$input_file" "$output_file" "Alignment with ${method}"
    fi
}

should_process_sequence() {
    # Check if a file should be processed based on SEQUENCE_TYPES filter
    # Returns 0 (true) if should process, 1 (false) if should skip
    local file=$1
    
    # If no filter specified, process all
    [[ ${#SEQUENCE_TYPES[@]} -eq 0 ]] && return 0
    
    # Check if file matches any of the specified types
    for seq_type in "${SEQUENCE_TYPES[@]}"; do
        case "$seq_type" in
            matk)
                [[ "$file" == *matk* || "$file" == *matK* ]] && return 0
                ;;
            rna)
                [[ "$file" == *rna* || "$file" == *18s* || "$file" == *18S* ]] && return 0
                ;;
            concat)
                [[ "$file" == *concatenated* || "$file" == *concat* ]] && return 0
                ;;
        esac
    done
    
    return 1
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
    run_with_space_time_log \
        --input "$aligned_file" \
        --output "$output_file" \
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
    run_with_space_time_log \
        --input "$aligned_file" \
        --output "$tree_file" \
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

# ========================================================================
# MAIN
# ========================================================================
main() {
    setup_logging
    parse_args "$@"

    # If no CLI groups provided, INPUT_GROUP already contains defaults
    # If defaults are empty, auto-discover from INPUT_DIR
    if [[ ${#INPUT_GROUP[@]} -eq 0 ]]; then
        if [[ -d "$INPUT_DIR" ]]; then
            while IFS= read -r -d '' d; do
                local base=$(basename "$d")
                if [[ -d "$d/b_RAW" ]]; then
                    INPUT_GROUP+=("$base")
                fi
            done < <(find "$INPUT_DIR" -mindepth 1 -maxdepth 1 -type d -print0)
        fi
    fi

    if [[ ${#INPUT_GROUP[@]} -eq 0 ]]; then
        log_error "No input groups provided and none found in '$INPUT_DIR'."
        log_info "Use --group NAME or --groups a,b,c"
        exit 1
    fi

    log_step "Starting Phylogenetic Analysis Pipeline"
    log_info "Input groups: ${INPUT_GROUP[*]}"
    [[ ${#SEQUENCE_TYPES[@]} -gt 0 ]] && log_info "Sequence types: ${SEQUENCE_TYPES[*]}"

    for group in "${INPUT_GROUP[@]}"; do
        local query_dir="$INPUT_DIR/$group"
        local output_subdir="$OUTPUT_DIR/$group"
        mkdir -p "$query_dir/b_RAW" "$output_subdir"

        if [ "$RUN_ALIGNMENT" = TRUE ]; then
            log_step "Step 2: Sequence Alignments for $group"
            for b_RAW_file in "$query_dir/b_RAW/"*.fasta; do
                [[ ! -f "$b_RAW_file" ]] && continue
                
                # Skip if doesn't match sequence type filter
                if ! should_process_sequence "$b_RAW_file"; then
                    log_info "Skipping $(basename "$b_RAW_file") (filtered by sequence type)"
                    continue
                fi
                
                format_fasta_fold_60 "$b_RAW_file"
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
                # Discover all aligned files
                aligned_files=("$query_dir/c_ALIGNMENT/${align_method}_aligned/"*.fas)
                
                for aligned_file in "${aligned_files[@]}"; do
                    [[ ! -f "$aligned_file" ]] && continue
                    
                    # Skip if doesn't match sequence type filter
                    if ! should_process_sequence "$aligned_file"; then
                        log_info "Skipping $(basename "$aligned_file") (filtered by sequence type)"
                        continue
                    fi

                    if [[ "$aligned_file" == *rna* || "$aligned_file" == *18s* ]]; then
                        config_file="$CONFIG_DIR/infer_ML_nucleotide_18s.mao"
                    else
                        config_file="$CONFIG_DIR/infer_ML_nucleotide_matK_and_concat.mao"
                    fi
                        
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

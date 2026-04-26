#!/usr/bin/env bash
set -u

pipeline_start=$(date +%s)
pipeline_start_human=$(date '+%Y-%m-%d %H:%M:%S')

print_logo() {
cat << "EOF"

╔══════════════════════════════════════╗
║                                      ║
║   ███╗   ██╗████████╗███╗   ███╗     ║
║   ████╗  ██║╚══██╔══╝████╗ ████║     ║
║   ██╔██╗ ██║   ██║   ██╔████╔██║     ║
║   ██║╚██╗██║   ██║   ██║╚██╔╝██║     ║
║   ██║ ╚████║   ██║   ██║ ╚═╝ ██║     ║
║   ╚═╝  ╚═══╝   ╚═╝   ╚═╝     ╚═╝     ║
║                                      ║
║            N T M s e q               ║
║   Whole genome sequencing analysis   ║ 
║    of non-tuberculous mycobacteria   ║       
║          by Margo Diricks            ║
╚══════════════════════════════════════╝

EOF
}
print_logo


##########################################
### METADATA
##########################################

SCRIPT_NAME="$(basename "$0")"
VERSION="2.0.0"
#NTMseq is for Research use only!

##########################################
### FUNCTIONS
##########################################

print_version() {
    echo "$SCRIPT_NAME version $VERSION"
}

print_help() {
cat <<EOF
$SCRIPT_NAME

Starter script for NTMseq, a pipeline for analysis of WGS data from
non-tuberculous mycobacteria.

USAGE:
  bash $Path/to/starter_NTMseq2.sh <config_file>

OPTIONS:
  -h, --help       Show this help message and exit
  -v, --version    Show version and exit

REQUIREMENT:
  A config file is always required.

CONFIG FILE:
  The config file must be a bash-style config file containing variable
  assignments (see example at github).


EOF
}

require_nonempty() {
    local value
    for value in "$@"; do
        if [[ -z "$value" ]]; then
            return 1
        fi
    done
    return 0
}

validate_yes_no() {
    local value="$1"
    local name="$2"

    if [[ "$value" != "Yes" && "$value" != "No" ]]; then
        echo "ERROR: $name must be set to Yes or No"
        exit 1
    fi
}

convert_genome_size_to_bp() {
    local size="$1"

    if [[ ! "$size" =~ ^[0-9]+([.][0-9]+)?M$ ]]; then
        echo "ERROR: genome_size must be in Mbp format, e.g. 5.1M or 5M" >&2
        return 1
    fi

    awk -v g="$size" '
    BEGIN {
        sub(/M$/, "", g)
        printf "%.0f\n", g * 1000000
    }'
}

run_module() {

    local label="$1"
    shift

    local start_time
    local end_time
    local runtime_min
    local status
    local start_human
    local end_human
    local logfile
    local safe_label

    # create safe logfile name
    safe_label=$(echo "$label" | tr ' ' '_' | tr -cd '[:alnum:]_')
    logfile="$LOGDIR/${safe_label}.log"

    echo "=================================================="
    echo "Starting: $label"
    echo "Command: $*"
    echo "Log file: $logfile"
    echo "=================================================="

    start_time=$(date +%s)
    start_human=$(date '+%Y-%m-%d %H:%M:%S')

    echo "MODULE: $label" > "$logfile"
    echo "START: $start_human" >> "$logfile"
    echo "COMMAND: $*" >> "$logfile"
    echo "==================================================" >> "$logfile"

    "$@" >> "$logfile" 2>&1
    status=$?

    end_time=$(date +%s)
    end_human=$(date '+%Y-%m-%d %H:%M:%S')

    runtime_min=$(awk "BEGIN {printf \"%.1f\", ($end_time-$start_time)/60}")

    echo -e "$label\t$start_human\t$end_human\t$runtime_min" >> "$PATH_output/time.txt"

    if [[ $status -eq 0 ]]; then
        echo "Finished: $label"
        echo "STATUS: OK" >> "$logfile"
    else
        echo "WARNING: $label failed with exit code $status"
        echo "Pipeline will continue with remaining modules."
        echo "STATUS: FAILED ($status)" >> "$logfile"
    fi

    echo "END: $end_human" >> "$logfile"
    echo "Runtime_minutes: $runtime_min" >> "$logfile"

    echo "Runtime: ${runtime_min} minutes"
    echo
}

check_module_requirements() {

    local module_name="$1"
    shift

    local missing=()
    local var_name
    local var_value

    while [[ $# -gt 0 ]]; do
        var_name="$1"
        var_value="$2"

        if [[ -z "$var_value" ]]; then
            missing+=("$var_name")
        fi

        shift 2
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Skipping $module_name: missing required setting(s): ${missing[*]}"
        echo -e "$module_name\tmissing required setting(s): ${missing[*]}\t-" >> "$PATH_output/failed_modules.txt"
        echo
        return 1
    fi

    return 0
}

detect_filetype() {
    if compgen -G "$PATH_fastQ/*.fastq.gz" > /dev/null; then
        filetype=".fastq.gz"
    elif compgen -G "$PATH_fastQ/*.fq.gz" > /dev/null; then
        filetype=".fq.gz"
    elif compgen -G "$PATH_fastQ/*.fastq" > /dev/null; then
        filetype=".fastq"
    elif compgen -G "$PATH_fastQ/*.fq" > /dev/null; then
        filetype=".fq"
    else
        echo "ERROR: Could not detect FASTQ file type in $PATH_fastQ"
        exit 1
    fi
}

detect_read_suffixes() {
    local file filename

    detect_filetype

    file="$(find "$PATH_fastQ" -maxdepth 1 -type f \( \
        -name "*${filetype}" \) | sort | head -n 1)"

    if [[ -z "$file" ]]; then
        echo "ERROR: No FASTQ files found in $PATH_fastQ"
        exit 1
    fi

    filename="$(basename "$file")"

    if [[ "$filename" == *"_R1_001${filetype}" ]]; then
        Fw="_R1_001"
        Rv="_R2_001"
    elif [[ "$filename" == *"_R1${filetype}" ]]; then
        Fw="_R1"
        Rv="_R2"
    elif [[ "$filename" == *"_1${filetype}" ]]; then
        Fw="_1"
        Rv="_2"
    else
        echo "ERROR: Could not auto-detect Fw and Rv from file name:"
        echo "       $filename"
        echo "Please set Fw and Rv manually in the config file."
        exit 1
    fi

    echo "Detected FASTQ file type: $filetype"
    echo "Detected forward suffix: $Fw"
    echo "Detected reverse suffix: $Rv"
    echo
}

##########################################
### ARGUMENT PARSING
##########################################

if [[ $# -eq 0 ]]; then
    echo "ERROR: A config file is required."
    echo
    print_help
    exit 1
fi

case "${1:-}" in
    -h|--help)
        print_help
        exit 0
        ;;
    -v|--version)
        print_version
        exit 0
        ;;
esac

CONFIG_FILE="$1"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Config file not found: $CONFIG_FILE"
    exit 1
fi

##########################################
### INTRO
##########################################

echo "hello World, this script was written by Margo Diricks (mdiricks@fz-borstel.de)!"
echo "This is a starter script for NTMseq, a pipeline for analysis of WGS data from non-tuberculous mycobacteria"
echo "NTMseq is for research use only!"
print_version
echo "Using config file: $CONFIG_FILE"

echo



##########################################
### LOAD CONFIG
##########################################

source "$CONFIG_FILE"

##########################################
### REQUIRED CORE VARIABLES
##########################################

required_vars=(
    PATH_scripts
    PATH_fastQ
    PATH_output
    species
    genome_size
    cpu
    PATH_tmp
    ass
)

for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        echo "ERROR: Required config variable is empty: $var"
        exit 1
    fi
done

##########################################
### DERIVED VARIABLES
##########################################

genome_size_full="$(convert_genome_size_to_bp "$genome_size")" || exit 1
PATH_fastA="${PATH_output}/Assemblies/FinalAssemblies"
set="$(date +%Y%m%d_%H%M)"

##########################################
### BASIC VALIDATION
##########################################

if [[ ! -d "$PATH_scripts" ]]; then
    echo "ERROR: PATH_scripts does not exist: $PATH_scripts"
    exit 1
fi

if [[ ! -d "$PATH_fastQ" ]]; then
    echo "ERROR: PATH_fastQ does not exist: $PATH_fastQ"
    exit 1
fi

mkdir -p "$PATH_output"
mkdir -p "$PATH_tmp"

LOGDIR="$PATH_output/logs"
mkdir -p "$LOGDIR"

echo -e "Module\tStart\tEnd\tRuntime_minutes" > "$PATH_output/time.txt"
echo -e "Module\tStatus_or_reason\tLog_or_details" > "$PATH_output/failed_modules.txt"

##########################################
### DETECT FILETYPE / READ SUFFIXES
##########################################

if [[ -z "${Fw:-}" && -z "${Rv:-}" ]]; then
    echo "Fw and Rv not provided in config. Detecting automatically..."
    detect_read_suffixes
elif [[ -n "${Fw:-}" && -n "${Rv:-}" ]]; then
    detect_filetype
    echo "Using Fw and Rv from config file."
    echo "Detected FASTQ file type: $filetype"
    echo "Configured forward suffix: $Fw"
    echo "Configured reverse suffix: $Rv"
    echo
else
    echo "ERROR: Please either provide both Fw and Rv in the config file, or leave both empty for auto-detection."
    exit 1
fi

echo "CPUs being used: $cpu"
echo "Run ID: $set"
echo

##########################################
### VALIDATE Yes/No SWITCHES
##########################################

validate_yes_no "$Do_multiqc" "Do_multiqc"
validate_yes_no "$Do_subsampling" "Do_subsampling"
validate_yes_no "$Do_fastp" "Do_fastp"
validate_yes_no "$Do_kraken2" "Do_kraken2"
validate_yes_no "$Do_NTMprofiler" "Do_NTMprofiler"
#validate_yes_no "$Do_subspecies" "Do_subspecies"
validate_yes_no "$Do_MLST_fastQ" "Do_MLST_fastQ"
validate_yes_no "$Do_assembly" "Do_assembly"
validate_yes_no "$Do_fastANI" "Do_fastANI"
validate_yes_no "$Do_fastANI_AllagainstAll" "Do_fastANI_AllagainstAll"
validate_yes_no "$Do_mash_fastQ" "Do_mash_fastQ"
validate_yes_no "$Do_mash_fastA" "Do_mash_fastA"
validate_yes_no "$Do_SRST2_customDB" "Do_SRST2_customDB"
validate_yes_no "$Do_platon" "Do_platon"
validate_yes_no "$Do_plasmidspades" "Do_plasmidspades"
validate_yes_no "$Do_amrfinder" "Do_amrfinder"
validate_yes_no "$Do_abricate" "Do_abricate"

##########################################
### PIPELINE
##########################################

## QUALITY CONTROL READS ###
if [[ "$Do_multiqc" == "Yes" ]]; then
    if check_module_requirements "multiqc" \
        "conda_env_multiqc" "${conda_env_multiqc:-}"; then
        run_module "Quality control on reads (fastQC/multiQC)" \
            bash "$PATH_scripts/starter_multiqc.sh" \
            -i "$PATH_fastQ" \
            -o "$PATH_output" \
            -c "$cpu" \
            -e "$conda_env_multiqc"
    fi
else
    echo "Quality control on reads skipped."
    echo
fi

### SUBSAMPLING ###
if [[ "$Do_subsampling" == "Yes" ]]; then
    if check_module_requirements "subsampling" \
        "conda_env_seqkit" "${conda_env_seqkit:-}" \
        "cov" "${cov:-}"; then
        run_module "subsampling" \
            bash "$PATH_scripts/starter_subsampling.sh" \
            -i "$PATH_fastQ" \
            -o "$PATH_output" \
            -g "$genome_size_full" \
            -d "$cov" \
            -c "$cpu" \
            -e "$conda_env_seqkit"
    fi
else
    echo "Subsampling skipped."
    echo
fi

### FASTQ PREPROCESSING ###
if [[ "$Do_fastp" == "Yes" ]]; then
    if check_module_requirements "fastp" \
        "conda_env_fastp" "${conda_env_fastp:-}"; then
        run_module "preprocess reads (fastp)" \
            bash "$PATH_scripts/starter_fastp.sh" \
            -i "$PATH_fastQ" \
            -o "$PATH_output" \
            -c "$cpu" \
            -e "$conda_env_fastp"
    fi
else
    echo "Preprocessing of reads skipped."
    echo
fi

### KRAKEN2 ###
if [[ "$Do_kraken2" == "Yes" ]]; then
    if check_module_requirements "kraken2" \
        "conda_env_kraken2" "${conda_env_kraken2:-}" \
        "db_kraken2" "${db_kraken2:-}"; then
        run_module "Contamination detection (kraken2)" \
            bash "$PATH_scripts/starter_kraken2.sh" \
            -i "$PATH_fastQ" \
            -o "$PATH_output" \
            -d "$db_kraken2" \
            -k "${db_krona:-}" \
            -c "$cpu" \
            -e "$conda_env_kraken2"

        run_module "parse kraken2 results" \
            perl "$PATH_scripts/kraken_parse_results.v2.0.0.pl" \
            -s "$species" \
            "$PATH_output"/kraken2/*.report
    fi
else
    echo "kraken2 on FastQ files skipped."
    echo
fi

### NTM PROFILER ###
if [[ "$Do_NTMprofiler" == "Yes" ]]; then
    if check_module_requirements "NTMprofiler" \
        "conda_env_NTMprofiler" "${conda_env_NTMprofiler:-}"; then
        run_module "NTM species and resistance detection (NTMprofiler)" \
            bash "$PATH_scripts/starter_NTMprofiler.sh" \
            -i "$PATH_fastQ" \
            -o "$PATH_output" \
            -n "$filetype" \
            -c "$cpu" \
            -e "$conda_env_NTMprofiler" \
            -f "$Fw" \
            -r "$Rv" \
            -s "$set"
    fi
else
    echo "Running NTMprofiler skipped."
    echo
fi

### SUBSPECIES ###
# if [[ "$Do_subspecies" == "Yes" ]] && [[ "$species" == "Mycobacteroides abscessus" ]]; then
    # if check_module_requirements "subspecies classification" "${conda_env_SRST2:-}" "${db_subspecies_Mab:-}"; then
        # run_module "subspecies classification of M. abscessus (MABsubspecifier)" \
            # bash "$PATH_scripts/starter_Subspecies_Mab_SRST2.sh" \
            # -i "$PATH_fastQ" \
            # -o "$PATH_output" \
            # -d "$db_subspecies_Mab" \
            # -c "$cpu" \
            # -e "$conda_env_SRST2" \
            # -f "$Fw" \
            # -r "$Rv" \
            # -s "$set" \
            # -t "$PATH_tmp"
    # fi
# elif [[ "$Do_subspecies" == "Yes" ]]; then
    # echo "Subspecies classification not available for $species."
    # echo
# else
    # echo "Subspecies analysis skipped."
    # echo
# fi

### MLST ###
if [[ "$Do_MLST_fastQ" == "Yes" ]]; then
    if check_module_requirements "MLST" \
        "conda_env_SRST2" "${conda_env_SRST2:-}" \
        "db_MLST_SRST2" "${db_MLST_SRST2:-}"; then
        run_module "MLST on FastQ files (SRST2)" \
            bash "$PATH_scripts/starter_MLST_SRST2.sh" \
            -i "$PATH_fastQ" \
            -o "$PATH_output" \
            -d "$db_MLST_SRST2" \
            -e "$conda_env_SRST2" \
            -p "$species"
    fi
else
    echo "MLST on FastQ files skipped."
    echo
fi

### ASSEMBLY ###
if [[ "$Do_assembly" == "Yes" ]]; then
    if check_module_requirements "assembly" \
        "conda_env_shovill" "${conda_env_shovill:-}" \
        "cov" "${cov:-}"; then
        run_module "assembly (shovill)" \
            bash "$PATH_scripts/starter_Assemble_usingShovill.sh" \
            -i "$PATH_fastQ" \
            -o "$PATH_output" \
            -g "$genome_size" \
            -d "$cov" \
            -c "$cpu" \
            -e "$conda_env_shovill" \
            -f "$Fw" \
            -r "$Rv" \
            -s "$set" \
            -a "$ass"
    fi
else
    echo "Assembly skipped."
    echo
fi

### MASH FASTQ ###
if [[ "$Do_mash_fastQ" == "Yes" ]]; then
    if check_module_requirements "mash FastQ" \
        "conda_env_mashtree" "${conda_env_mashtree:-}"; then
        run_module "mash on FastQ files" \
            bash "$PATH_scripts/starter_Mashtree.sh" \
            -i "$PATH_fastQ" \
            -o "$PATH_output" \
            -n "$filetype" \
            -e "$conda_env_mashtree" \
            -s "$set"
    fi
else
    echo "mash on FastQ files skipped."
    echo
fi

### MASH FASTA ###
if [[ "$Do_mash_fastA" == "Yes" ]]; then
    if check_module_requirements "mash FastA" \
        "conda_env_mashtree" "${conda_env_mashtree:-}"; then
        run_module "mash on FastA files" \
            bash "$PATH_scripts/starter_Mashtree.sh" \
            -i "$PATH_fastA" \
            -o "$PATH_output" \
            -n ".fasta" \
            -e "$conda_env_mashtree" \
            -s "$set"
    fi
else
    echo "mash on FastA files skipped."
    echo
fi

### FASTANI ###
if [[ "$Do_fastANI" == "Yes" ]]; then
    if check_module_requirements "fastANI" \
        "conda_env_fastANI" "${conda_env_fastANI:-}" \
        "fastANI_ref" "${fastANI_ref:-}"; then
        run_module "fastANI" \
            bash "$PATH_scripts/starter_fastANI.sh" \
            -i "$PATH_fastA" \
            -o "$PATH_output" \
            -r "$fastANI_ref" \
            -e "$conda_env_fastANI"
    fi
else
    echo "FastANI skipped."
    echo
fi

### FASTANI ALL-AGAINST-ALL ###
if [[ "$Do_fastANI_AllagainstAll" == "Yes" ]]; then
    if check_module_requirements "fastANI all-against-all" \
        "conda_env_fastANI" "${conda_env_fastANI:-}"; then
        run_module "fastANI all against all" \
            bash "$PATH_scripts/starter_fastANI_AllAgainstAll.sh" \
            -i "$PATH_fastA" \
            -o "$PATH_output" \
            -e "$conda_env_fastANI" \
            -c "$cpu"
    fi
else
    echo "FastANI all-against-all skipped."
    echo
fi

### PLASMIDSPADES ###
if [[ "$Do_plasmidspades" == "Yes" ]]; then
    if check_module_requirements "plasmidspades" \
        "conda_env_spades" "${conda_env_spades:-}" \
        "conda_env_platon" "${conda_env_platon:-}" \
        "db_platon" "${db_platon:-}"; then
        run_module "plasmid assembly using plasmidspades" \
            bash "$PATH_scripts/starter_plasmidspades.sh" \
            -i "$PATH_fastQ" \
            -o "$PATH_output" \
            -c "$cpu" \
            -e "$conda_env_spades" \
            -f "$Fw" \
            -r "$Rv" \
            -s "$set" \
            -t "$PATH_tmp"

        run_module "platon on plasmidspades assemblies" \
            bash "$PATH_scripts/starter_Platon.sh" \
            -i "$PATH_output/Plasmidspades/FinalAssemblies" \
            -o "$PATH_output/Plasmidspades/FinalAssemblies" \
            -d "$db_platon" \
            -c "$cpu" \
            -e "$conda_env_platon" \
            -s "$set"
    fi
else
    echo "Plasmid assembly using plasmidspades skipped."
    echo
fi

### SRST2 CUSTOM DB ###
if [[ "$Do_SRST2_customDB" == "Yes" ]]; then
    if check_module_requirements "SRST2 custom DB" \
        "conda_env_SRST2" "${conda_env_SRST2:-}" \
        "db_custom_SRST2" "${db_custom_SRST2:-}"; then
        customDB="$(basename "$db_custom_SRST2" | cut -d '.' -f 1)"
        customDB_SRST2="${customDB}_SRST2.fasta"

        if [[ ! -f "$(dirname "$db_custom_SRST2")/$customDB_SRST2" ]]; then
            run_module "convert custom DB to SRST2 database" \
                bash "$PATH_scripts/customDB_to_SRST2_db.sh" \
                -d "$db_custom_SRST2"
        else
            echo "SRST2 compatible custom database found."
            echo
        fi

        run_module "plasmid detection with SRST2 using custom database" \
            bash "$PATH_scripts/starter_customDB_SRST2.sh" \
            -i "$PATH_fastQ" \
            -o "$PATH_output" \
            -d "$(dirname "$db_custom_SRST2")/$customDB_SRST2" \
            -c "$cpu" \
            -e "$conda_env_SRST2" \
            -f "$Fw" \
            -r "$Rv" \
            -s "$set" \
            -t "$PATH_tmp"
    fi
else
    echo "Plasmid detection with SRST2 using custom database skipped."
    echo
fi

### PLATON ###
if [[ "$Do_platon" == "Yes" ]]; then
    if check_module_requirements "platon" \
        "conda_env_platon" "${conda_env_platon:-}" \
        "db_platon" "${db_platon:-}"; then
        run_module "plasmid detection with platon" \
            bash "$PATH_scripts/starter_platon.sh" \
            -i "$PATH_fastA" \
            -o "$PATH_output" \
            -d "$db_platon" \
            -c "$cpu" \
            -e "$conda_env_platon" \
            -s "$set"
    fi
else
    echo "Plasmid detection with platon skipped."
    echo
fi

### AMRFINDER ###
if [[ "$Do_amrfinder" == "Yes" ]]; then
    if check_module_requirements "AMRFinderPlus" \
        "conda_env_AMRfinder" "${conda_env_AMRfinder:-}" \
        "db_AMRfinder" "${db_AMRfinder:-}"; then
        run_module "AMRFinderPlus" \
            bash "$PATH_scripts/starter_amrfinder.sh" \
            -i "$PATH_fastA" \
            -o "$PATH_output" \
            -c "$cpu" \
            -e "$conda_env_AMRfinder" \
            -d "$db_AMRfinder"
    fi
else
    echo "Resistance gene detection with AMRFinderPlus skipped."
    echo
fi

### ABRICATE ###
if [[ "$Do_abricate" == "Yes" ]]; then
    if check_module_requirements "abricate" \
        "conda_env_abricate" "${conda_env_abricate:-}" \
        "db_abricate" "${db_abricate:-}"; then
        run_module "abricate" \
            bash "$PATH_scripts/starter_abricate.sh" \
            -i "$PATH_fastA" \
            -o "$PATH_output" \
            -c "$cpu" \
            -e "$conda_env_abricate" \
            -d "$db_abricate"
    fi
else
    echo "Abricate skipped."
    echo
fi


pipeline_end=$(date +%s)
pipeline_end_human=$(date '+%Y-%m-%d %H:%M:%S')

pipeline_runtime_min=$(awk "BEGIN {printf \"%.2f\", ($pipeline_end-$pipeline_start)/60}")

echo -e "TOTAL_PIPELINE\t$pipeline_start_human\t$pipeline_end_human\t$pipeline_runtime_min" >> "$PATH_output/time.txt"
echo "Script finished in $pipeline_runtime_min min!"
exit 0
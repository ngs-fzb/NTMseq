#!/usr/bin/env bash

###Usage###
# bash $PathToScript/Scriptname.sh -h

###Author###
#Margo Diricks (mdiricks@fz-borstel.de)!"

###Version###
version="2.0.0"

#Version changes from 1.0.0
#added code for itol annotation file

###Function###
#"This script starts NTMprofiler (Author: Jody Phelan) to predict NTM species and resistance"

###Required packages###
# NTMprofiler (https://github.com/jodyphelan/NTM-Profiler)

###Required parameters - via command line###
#-i PATH_input=""
#-o PATH_output=""
#-n filetype=""

###Optional parameters that can be changed###
Fw="_R1" #Change if your fastQ files are not SampleName_R1.fastq.gz
Rv="_R2" #Change if your fastQ files are not SampleName_R2.fastq.gz
cpu=8 #$(lscpu | grep -E '^CPU\(' | awk '{print $(NF)}') #Uses all available threads
set="SampleSet"
conda_env="NTMprofiler"
platform="illumina"

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "Syntax: NameScript.sh [parameters]"
   echo "Required parameters:"
   echo "-i     Full path to folder where input files (fastQ or fastA) are stored"
   echo "-o     Full path to folder where result files need to be stored"
   echo "-n     Input file type: .fastq.gz or .fasta"
   echo ""
   echo "Optional parameters":
   echo "-c     amount of cpus that need to be used (depends on your hardware configuration); Default: All"
   echo "-e     Name of conda environment; Default: NTMprofiler"
   echo "-f     Forward read notation; Default: _R1"
   echo "-r     Reverse read notation; Default: _R2"
   echo "-s     Name of sample set - used for file naming; Default: Sampleset"
   echo ""
   echo "-v     Display version"
   echo "-h     Display help"
}

############################################################
# Get parameters                                                #
############################################################

while getopts ":hi:o:n:c:f:r:s:e::v" option; do #:h does not need argument, f: does need argument
   case $option in
      h) # display Help
         Help
         exit;;
      i) #
         PATH_input=$OPTARG;;
      o) # 
         PATH_output_tmp=$OPTARG
         PATH_output=$PATH_output_tmp/NTMprofiler ;;
      n) # 
         filetype=$OPTARG;;
      c) # 
         cpu=$OPTARG;;
      f) # 
         Fw=$OPTARG;;
      r) # 
         Rv=$OPTARG;;
      s) # 
         set=$OPTARG;;
      e) # 
         conda_env=$OPTARG;;
      v) # display Version
         echo $version
         exit;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

###Check if required parameters are provided###
if [[ -z "$PATH_input" ]] || [[ -z "$PATH_output" ]] || [[ -z "$filetype" ]]
then
	echo "Please provide all required arguments (-i PATH_input, -o PATH_output and -d db_subspecies_Mab)! use starter_NTMprofiler.sh -h for help on syntax"
	exit
fi

#No changes required below this point
###############################################################################CODE#################################################################################
###Remove previous files
#rm $PATH_output/Failed.txt

###Create folders###
mkdir -p $PATH_output

###Activate conda environment###

eval "$(conda shell.bash hook)"
conda activate $conda_env

###Create info file###

date > $PATH_output/info.txt
echo "Version script: "$version >> $PATH_output/info.txt
echo "NTMprofiler version: "$(ntm-profiler profile --version) >> $PATH_output/info.txt
echo "Input files: "$PATH_input >> $PATH_output/info.txt
echo "Amount of threads used: "$cpu >> $PATH_output/info.txt
echo "Sample set: "$set >> $PATH_output/info.txt
echo "Conda environment: "$conda_env >> $PATH_output/info.txt

cd $PATH_output

if [[ "$filetype" == ".fastq" ]] || [[ "$filetype" == ".fastq.gz" ]]
then
	echo "Amount of samples in input folder:" $(ls $PATH_input/*1$filetype | wc -l) >> $PATH_output/info.txt
	for fastq in $PATH_input/*$Fw$filetype
	do
		SampleName=$(basename $fastq| cut -d '_' -f 1)
		if [[ ! -s $SampleName".results.txt" ]]
		then
			ntm-profiler profile --read1 $fastq --read2 $(echo $fastq | sed "s/$Fw$filetype$/$Rv$filetype/1") --platform $platform --dir $PATH_output --threads $cpu --csv --txt -p $SampleName
			#Clean up big files (GB file sizes)
		else
			echo "Sample was already analyzed"
		fi
	done
elif [[ "$filetype" == ".fasta" ]]
then
	echo "Amount of samples in input folder:" $(ls $PATH_input/*$filetype | wc -l) >> $PATH_output/info.txt
	for fasta in $PATH_input/*$filetype 
	do
		SampleName=$(basename $fastq | cut -d '_' -f 1 | cut -d '.' -f 1 )
		if [[ ! -s $SampleName".results.txt" ]] 
		then 
			ntm-profiler profile -a $fasta  $PATH_output --threads $cpu --csv --txt -p $SampleName 
		else
			echo "Sample was already analyzed"
		fi
	done
fi

###Summarize results
ntm-profiler collate

###Create iTOL annotation files from NTMprofiler collate output
# The color files are expected in an "itol" folder next to the "scripts" folder:
# NTMseq/
# ├── scripts/
# │   └── starter_NTMprofiler.sh
# └── itol/
#     ├── itol_species_colors.csv
#     └── itol_subspecies_colors.csv
#
# The CSV format is:
# label,color
# Mycobacterium abscessus,#4cbb17
#
# Users can add/change labels and colors in these files without editing this script.
# Only labels that are actually detected in the current dataset are shown in the iTOL legend.

create_itol_annotations() {
    local collate_file="$1"
    local outdir="$2"

    local script_dir
    local repo_dir
    local itol_dir
    local species_color_file
    local subspecies_color_file

    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    repo_dir="$(dirname "$script_dir")"
    itol_dir="$repo_dir/itol"

    species_color_file="$itol_dir/itol_species_colors.csv"
    subspecies_color_file="$itol_dir/itol_subspecies_colors.csv"

    local species_itol="$outdir/itol_NTMprofiler_Species.txt"
    local subspecies_itol="$outdir/itol_NTMprofiler_Subspecies.txt"

    if [[ ! -s "$collate_file" ]]; then
        echo "WARNING: Cannot create iTOL annotation files because collate file was not found or is empty: $collate_file"
        return 0
    fi

    if [[ ! -s "$species_color_file" ]]; then
        echo "ERROR: Species color file not found or empty: $species_color_file"
        echo "Expected location: NTMseq/itol/itol_species_colors.csv"
        return 1
    fi

    if [[ ! -s "$subspecies_color_file" ]]; then
        echo "ERROR: Subspecies color file not found or empty: $subspecies_color_file"
        echo "Expected location: NTMseq/itol/itol_subspecies_colors.csv"
        return 1
    fi

    awk -v species_itol="$species_itol" \
        -v subspecies_itol="$subspecies_itol" \
        -v species_color_file="$species_color_file" \
        -v subspecies_color_file="$subspecies_color_file" \
        -v collate_file="$collate_file" '
    function trim(x) {
        gsub(/^[ \t\r\n]+/, "", x)
        gsub(/[ \t\r\n]+$/, "", x)
        return x
    }

    function read_color_line(line, label, color, arr) {
        split(line, arr, ",")
        label = trim(arr[1])
        color = trim(arr[2])

        if (label == "" || color == "") return
        if (label == "label" && color == "color") return

        if (FILENAME == species_color_file) {
            species_color[label] = color
            species_order[++species_color_count] = label
        } else if (FILENAME == subspecies_color_file) {
            subspecies_color[label] = color
            subspecies_order[++subspecies_color_count] = label
        }
    }

    function classify_species(x) {
        x = trim(x)

        # Empty species calls are written as the special label "Empty".
        # Its color is read from itol_species_colors.csv.
        if (x == "") return "Empty"

        # Treat M. gwanakae as M. chelonae for the iTOL species annotation.
        if (x == "Mycobacterium gwanakae") return "Mycobacterium chelonae"

        # NTMprofiler potential novel species, e.g. Mycobacterium sp001 or Mycobacterium sp.001.
        if (x ~ /^Mycobacterium sp[.]?[0-9]+$/) return "Potential novel species"

        # Any species listed in itol_species_colors.csv is accepted directly.
        # This lets users add additional species without editing this script.
        if (x in species_color) return x

        return "Other"
    }

    function clean_subspecies(x) {
        x = trim(x)

        if (x == "") return "Unknown"

        # Multiple semicolon-separated subspecies calls are classified as mix.
        # Example: subsp. abscessus; subsp. massiliense -> mix
        if (x ~ /;/) return "mix"

        gsub(/^subsp[.]?[ ]+/, "", x)
        gsub(/^subspecies[ ]+/, "", x)

        # Any subspecies listed in itol_subspecies_colors.csv is accepted directly.
        # This lets users add additional subspecies without editing this script.
        if (x in subspecies_color) return x

        return "Other"
    }

    function color_for_species(label) {
        if (label in species_color) return species_color[label]
        if ("Other" in species_color) return species_color["Other"]
        return "#dbd7d2"
    }

    function color_for_subspecies(label) {
        if (label in subspecies_color) return subspecies_color[label]
        if ("Other" in subspecies_color) return subspecies_color["Other"]
        return "#7f7f7f"
    }

    function add_species_seen(label) {
        if (!(label in species_seen)) {
            species_seen[label] = 1
        }
    }

    function add_subspecies_seen(label) {
        if (!(label in subspecies_seen)) {
            subspecies_seen[label] = 1
        }
    }

    function append_legend_entry(label, color,    shown_label) {
        shown_label = label
        if (shown_label == "Empty") shown_label = "No species call"

        legend_count++
        if (legend_count == 1) {
            legend_shapes = "1"
            legend_colors = color
            legend_labels = shown_label
        } else {
            legend_shapes = legend_shapes "\t1"
            legend_colors = legend_colors "\t" color
            legend_labels = legend_labels "\t" shown_label
        }
    }

    FILENAME == species_color_file {
        read_color_line($0)
        next
    }

    FILENAME == subspecies_color_file {
        read_color_line($0)
        next
    }

    FILENAME == collate_file {
        n = split($0, field, "\t")

        if (FNR == 1) {
            for (i = 1; i <= n; i++) {
                if (field[i] == "id") id_col = i
                if (field[i] == "species") species_col = i
                if (field[i] == "barcode") barcode_col = i
            }
            if (id_col == "" || species_col == "" || barcode_col == "") {
                print "ERROR: Expected columns id, species and barcode in " FILENAME > "/dev/stderr"
                exit 1
            }
            next
        }

        sample = trim(field[id_col])
        if (sample == "") next

        species_label = classify_species(field[species_col])
        subspecies_label = clean_subspecies(field[barcode_col])

        sample_count++
        sample_order[sample_count] = sample
        sample_species[sample] = species_label
        sample_subspecies[sample] = subspecies_label

        add_species_seen(species_label)
        add_subspecies_seen(subspecies_label)
        next
    }

    END {
        print "DATASET_COLORSTRIP" > species_itol
        print "SEPARATOR TAB" >> species_itol
        print "DATASET_SCALE\t0" >> species_itol
        print "DATASET_LABEL\tNTMprofiler_species" >> species_itol
        print "COLOR\t#ff0000" >> species_itol
		print "BORDER_WIDTH\t1" >> species_itol
		print "BORDER_COLOR\t#000000" >> species_itol
        print "LEGEND_TITLE\tSpecies" >> species_itol


        legend_count = 0
        legend_shapes = ""
        legend_colors = ""
        legend_labels = ""

        for (i = 1; i <= species_color_count; i++) {
            label = species_order[i]
            if (label in species_seen) {
                append_legend_entry(label, species_color[label])
            }
        }

        if (legend_count > 0) {
            print "LEGEND_SHAPES\t" legend_shapes >> species_itol
            print "LEGEND_COLORS\t" legend_colors >> species_itol
            print "LEGEND_LABELS\t" legend_labels >> species_itol
        }

        print "DATA" >> species_itol
        for (i = 1; i <= sample_count; i++) {
            sample = sample_order[i]
            print sample "\t" color_for_species(sample_species[sample]) >> species_itol
        }

        print "DATASET_COLORSTRIP" > subspecies_itol
        print "SEPARATOR TAB" >> subspecies_itol
        print "DATASET_SCALE\t0" >> subspecies_itol
        print "DATASET_LABEL\tNTMprofiler_subspecies" >> subspecies_itol
        print "COLOR\t#ff0000" >> subspecies_itol
		print "BORDER_WIDTH\t1" >> subspecies_itol
		print "BORDER_COLOR\t#000000" >> subspecies_itol
        print "LEGEND_TITLE\tSubspecies" >> subspecies_itol

        legend_count = 0
        legend_shapes = ""
        legend_colors = ""
        legend_labels = ""

        for (i = 1; i <= subspecies_color_count; i++) {
            label = subspecies_order[i]
            if (label in subspecies_seen) {
                append_legend_entry(label, subspecies_color[label])
            }
        }

        if (legend_count > 0) {
            print "LEGEND_SHAPES\t" legend_shapes >> subspecies_itol
            print "LEGEND_COLORS\t" legend_colors >> subspecies_itol
            print "LEGEND_LABELS\t" legend_labels >> subspecies_itol
        }

        print "DATA" >> subspecies_itol
        for (i = 1; i <= sample_count; i++) {
            sample = sample_order[i]
            print sample "\t" color_for_subspecies(sample_subspecies[sample]) >> subspecies_itol
        }
    }' "$species_color_file" "$subspecies_color_file" "$collate_file"

    echo "Created iTOL species annotation: $species_itol"
    echo "Created iTOL subspecies annotation: $subspecies_itol"
}

create_itol_annotations "$PATH_output/ntmprofiler.collate.txt" "$PATH_output"



date >> $PATH_output/info.txt

#Clean up big files (GB file sizes) + small files (do it only at this point because I don´t know what collate uses)
rm $PATH_output/*.bam
rm $PATH_output/*-*-*-*.kmers.txt #BIG!
rm $PATH_output/*.fq.gz #BIG!
rm $PATH_output/*.mash_dist.txt
#rm $PATH_output/*.json Don´t do this, otherwise you cannot use the collate function again (important if you process samples in different batches)
rm $PATH_output/*.results.csv

conda deactivate
echo "Script finished!"
exit

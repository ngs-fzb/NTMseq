# NTMseq
This repository contains NTMseq, a comprehensive bioinformatics pipeline for the analysis of whole-genome sequencing data from non-tuberculous mycobacteria (NTM), including quality control, taxonomic classification, assembly, approximate phylogenetic analysis, plasmid and (drug) resistance analysis.

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

### Requirements
- Linux-based system (preferably not WSL on Windows as some tools might not be compatible)
- Basic command-line experience
- Conda (Miniconda or Anaconda)

### Setup

1. Clone the repository:

git clone https://github.com/ngs-fzb/NTMseq.git
cd NTMseq

2. Run the installation script

bash installation_NTMseq.sh

Note: This will create separate conda environments for each tool used in the pipeline.

3. Download required databases
⚠️ Note: Some databases are large (>50 GB) and must be downloaded in a location with enough storage space.

_Taxonomy_
1. Kraken 2: [https://benlangmead.github.io/aws-indexes/k2] --> choose your preferred database, depending on the space you have available (
TLDR: wget https://genome-idx.s3.amazonaws.com/kraken/k2_pluspf_16_GB_20260226.tar.gz && tar -xvzf k2_pluspf_16_GB_20260226.tar.gz

3. Krona: [https://github.com/marbl/Krona/wiki/KronaTools]
TLDR: conda run -n NTMseq_kraken2 ktUpdateTaxonomy.sh /database_directory

_Typing_
1. MLST via SRST2: [https://github.com/katholt/srst2]
This database is updated automatically when running the pipeline. However, due to a recent change in data access policy at pubMLST [https://pubmlst.org/change-data-access-policy], only ST types and profiles submitted up to December 2024 will be reported. For the newest ST types, please submit your assemblies directly to the pubMLST website, after login.
Currently, MLST typing is only available for _M. abscessus_

_Resistance prediction_
1. NTM-Profiler: [https://github.com/jodyphelan/NTM-Profiler] 
TLDR: conda run -n NTMseq_NTMprofiler ntm-profiler update_db

2. AMRFinder: [https://github.com/ncbi/amr/wiki/Upgrading#database-updates]
TLDR: conda run -n NTMseq_NTMprofiler amrfinder_update -d </database_directory> #To update database in user-specified directory

_Plasmid prediction_
Custom plasmid database: [https://ccb-microbe.cs.uni-saarland.de/plsdb/plasmids/]
Note:
Alternatively, download the multi-fasta file PLSDB_mycobacteriaceae_DATE_AMOUNT.fasta in this repo for a curated database of mycobacterial plasmids 

Optional:
Platon: [https://zenodo.org/search?page=1&size=20&q=conceptrecid:3349651&all_versions&sort=-version] or [https://github.com/oschwengers/platon#database]

### Usage

1. Configure your analysis in:
config_NTMseq.txt

(e.g. paths to FASTQ files, databases, output directory, analyses you want to do)

Run the pipeline:
bash starter_NTMseq.sh config_NTMseq.txt

### Help

Do you need help or have feature requests? Just drop me a mail @ mdiricks@fz-borstel.de

### Citation
Paper in progress...
Please use this github page as temporary reference.

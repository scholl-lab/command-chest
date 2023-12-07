# Importing necessary Python modules
import glob  # Used for file path pattern matching
import os    # Used for path and filename manipulations
import functools    # Used for partial function application

# ----------------------------------------------------------------------------------- #
# Load configuration file containing user-defined settings
configfile: "config.yaml"

# Define temporary directory using an environment variable (usually set by the cluster scheduler)
SCRATCH_DIR = os.environ.get('TMPDIR')

# Define the directories for input and output
# Input Directory: Where the BAM files are located
BAM_DIR = config["bam_directory"]

# Output Directory: Where the processed files will be saved
OUT_DIR = config["output_directory"]

# Helper function to return memory based on the number of threads
def get_mem_from_threads(wildcards, threads):
    return threads * 4000
# ----------------------------------------------------------------------------------- #


# ----------------------------------------------------------------------------------- #
# Define result directories using functools.partial to join paths with the output folder
prefix_results = functools.partial(os.path.join, OUT_DIR)
LOG_DIR = prefix_results('logs')

# Creating a list of basenames (without .bam extension) of all BAM files in the input directory
# glob.glob() fetches all paths matching the "*.bam" pattern in BAM_DIR
# os.path.basename() extracts the file name from the path
# os.path.splitext()[0] removes the '.bam' extension from the file name
bam_filenames = [os.path.splitext(os.path.basename(f))[0] for f in glob.glob(BAM_DIR + "*.bam")]

# Creating a list of output file paths, replacing '.bam' with '.txt' in each filename
output_files = [OUT_DIR + f + '.txt' for f in bam_filenames]

# Final concatenated file name
final_output = OUT_DIR + "combined_output.txt"

# ----------------------------------------------------------------------------------- #


# ----------------------------------------------------------------------------------- #
# Rule 'all' serves as the entry point for the workflow and specifies the final output file
rule all:
    input:
        final_output

# Rule for processing each BAM file
# Uses samtools, cut, awk, sort, and uniq commands to process the data
rule process_bam:
    input:
        bam_file = BAM_DIR + "{sample}.bam"  # Input BAM file with wildcard for the filename
    output:
        processed_file = OUT_DIR + "{sample}.txt"  # Output file path with corresponding wildcard
    threads: 2  # Adjust as necessary
    resources:
        mem_mb = get_mem_from_threads,
        time = '72:00:00',
        tmpdir = SCRATCH_DIR
    conda:
        "gatk"
    log:
        os.path.join(LOG_DIR, "{sample}.process_bam.log")
    shell:
        """
        # Processing pipeline:
        # 1. samtools view - Converts BAM to SAM and outputs to stdout
        # 2. cut -f1 - Extracts the first field from each line
        # 3. awk -F: - Splits lines by ':' and prints first four columns separated by tabs
        # 4. sort | uniq - Sorts the lines and removes duplicates
        # The final result is redirected to the output file
        samtools view {input.bam_file} | cut -f1 | awk -F: '{{print $1"\\t"$2"\\t"$3"\\t"$4}}' | sort | uniq > {output.processed_file}
        """

# Rule to concatenate all output files with a header
rule concatenate_outputs:
    input:
        output_files
    output:
        final_output
    threads: 2  # Adjust as necessary
    resources:
        mem_mb = get_mem_from_threads,
        time = '72:00:00',
        tmpdir = SCRATCH_DIR
    conda:
        "gatk"
    log:
        os.path.join(LOG_DIR, "concatenate_outputs.log")
    shell:
        """
        # Concatenation pipeline:
        # 1. Create a header with column names: instrument, run, flowcell, lane
        # 2. Concatenate all processed files into a single file with the header.
        # Use grep to add filenames and sed to replace '.txt:' with a tab and remove the path
        echo -e "sample\\tinstrument\\trun\\tflowcell\\tlane" > {output}
        grep --with-filename '.' {input} | sed 's/\\.txt:/\\t/' | sed 's/^.*\///' >> {output}
        """
# ----------------------------------------------------------------------------------- #
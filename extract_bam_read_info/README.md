# README: extract_bam_read_info.smk

## Overview
`extract_bam_read_info.smk` is a Snakemake workflow designed to process BAM files and extract specific read information. The script uses tools such as `samtools`, `cut`, `awk`, `sort`, and `uniq` to parse BAM files, extract and transform read information, and then concatenate the results into a single output file.

## Read Name Format
The workflow extracts the following components from the Illumina read names found in the BAM files:
- **Instrument**: The unique name of the sequencing instrument.
- **Run ID**: The number identifying the run.
- **Flowcell ID**: The unique identifier for the flowcell.
- **Lane**: The lane number on the flowcell.

An representative explanation of an Illumina read name is provided here (source: https://www.gdc-docs.ethz.ch/MDA/site/getdata/):
![Data format: fastq](https://www.gdc-docs.ethz.ch/MDA/images/fastq.png)

## Requirements
- Snakemake
- samtools
- Python (with `yaml` and `glob` modules)
- A configuration file in YAML format (`config.yaml`)

## Configuration
Before running the script, you need to set up the `config.yaml` file with the following parameters:
- `bam_directory`: The directory containing the BAM files to process.
- `output_directory`: The directory where the processed files will be saved.

Example `config.yaml`:
```yaml
bam_directory: "/path/to/bam/files/"
output_directory: "/path/to/output/"
```

## Workflow Steps
1. **BAM File Processing (`process_bam` rule)**: This step involves converting each BAM file to a SAM format using `samtools view`, extracting the first field (read name), splitting lines by `:`, and sorting and removing duplicate entries.
2. **Concatenating Outputs (`concatenate_outputs` rule)**: This step concatenates all individual output files into a single file with a header.

## Usage
To run the workflow, navigate to the directory containing the `extract_bam_read_info.smk` file and execute the following command:

```bash
snakemake --snakefile extract_bam_read_info.smk --cores [number_of_cores]
```

Replace `[number_of_cores]` with the desired number of cores for parallel processing.

## Example Command Line
```bash
snakemake --snakefile extract_bam_read_info.smk --cores 4
```

## Example Outputs
- Processed text files for each BAM file in the format `{sample}.txt` in the specified output directory.
- A final concatenated file `combined_output.txt` in the specified output directory, containing processed data from all BAM files with a header.

### Content of a Processed File (`sample.txt`)
```
instrument1  run1  flowcell1  lane1
instrument2  run2  flowcell2  lane2
...
```

### Content of the Final Output File (`combined_output.txt`)
```
instrument  run  flowcell  lane
instrument1  run1  flowcell1  lane1
instrument2  run2  flowcell2  lane2
...
```

## Logging
Logs for each processed file are stored in the `logs` directory within the output directory, allowing for easy troubleshooting and process tracking.

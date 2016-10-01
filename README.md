## Genome assembly

Usage: ./genome_assembly.sh <input_file> <output_directory> <fermi_timeout_sec>  
Ex: ./genome_assembly.sh input.fna output 40

This implementation handles all combinations of cases:  
- single/paired reads  
- read sizes : 50, 100, 500 bp  
- depth : 10, 30, 100 X  
- error rates : 0.1% 1% 10%

### Implementation steps  
1. For each scenario use idba sim_reads to generate corresponding reads file  
2. For paired reads use idba_ud to generate contig.fa. Use raw_n50 to generate counts report to output/report.txt  
3. For single reads use fermi 
For certain values fermi remains blocked so this program expects a timeout after which the process is killed.
If the process finishes successfully, a counts report is generated to output/report.txt 





#!/bin/bash
#this script assumes necessary packages are already installed
printf "\n##########\nThis program expects input.fna, run_fermi.pl, fermi files in root\n"
printf "Usage: ./generate_assembly.sh <input_file> <output_directory> <fermi_timeout_sec> "
printf "\n Ex: ./generate_assembly.sh input.fna output 40"
printf "\nResults are generated in output/report.txt"
printf "\n##########\n\n"
#get input arguments
args=("$@")

input_file=$1
output_dir=$2
fermi_timeout=$3


#global variables
declare -a modes=( "single" "paired" )
declare -a bp_list=( 50 100 500)
declare -a depth_list=( 10 30 100 )
declare -a error_rate_list=(0.01 0.1 1)


validate_input()
{
  args_len=${#args[@]}
  if [ $args_len -ne 3 ];
  then 
    echo "Please provide all 3 mandatory input parameters"
    exit 64
  fi

  if [ -z "$input_file" ] || [ ! -f "$input_file" ];
  then
    echo "Please provide input.fna file next to this script"
    exit 64
  fi

  run_fermi_file="run-fermi.pl"
  fermi_file="fermi"

  if [ ! -f $run_fermi_file ] || [ ! -f $run_fermi_file ]; 
  then
    echo "Please provide fermi and run_fermi.pl file next to this script"
    exit 64
  fi
}
# creates output folders
setup ()
{
  if [ -d "$output_dir" ] ; then
    echo "Removing existing directory $output_dir"
    rm -r "$output_dir"
  fi

  echo "Creating output directory : $output_dir"
  mkdir "$output_dir"

  for mode in "${modes[@]}"
  do
    for bp in "${bp_list[@]}"
    do
      for error_rate in "${error_rate_list[@]}"
      do
        for depth in "${depth_list[@]}"
        do
          folder="$output_dir/$mode"
          folder+="__bp_$bp"
          folder+="__depth_$depth"
          folder+="__error$error_rate"
          echo "folder $folder"
          mkdir "$folder"
          copy_input_file "$folder"
          generate_read "$folder" "$mode" "$bp" "$depth" "$error_rate" 
        done
      done
    done
  done

}

copy_input_file ()
{
  cp "$input_file" "$1"
}

generate_read ()
{
  if [ $2 = "paired" ];
  then
    handle_paired_reads $1 $2 $3 $4 $5 
  else
    handle_single_reads $1 $2 $3 $4 $5 
  fi
}

handle_single_reads ()
{
  pushd "$1"
  sim_reads "$input_file" sim_reads.fa --read_length $3 --depth $4 --error_rate $5 >> ../sim_reads.log

  #check if file is empty
  if [ -s sim_reads.fa ]
  then
    #use fermi
    ../../run-fermi.pl -ct8 -e ../../fermi sim_reads.fa >fmdef.mak
    make -f fmdef.mak -j 8 > fmdef.log 2>&1 &


    #Sometimes fermi remains blocked, blocking the entire program
    #If fermi doesn't finish in $fermi_timeout seconds => kill the process and move on
    
    TASK_PID=$!
    sleep $fermi_timeout && kill -9 $TASK_PID &
    wait $TASK_PID

    fermi_output="fmdef.p5.fq.gz" 
    if [ ! -f $fermi_output ]; 
    then
      echo "Failed to execute FERMI for $1 $2 read length $3 depth $4 error $5" >> ../fermi_errors.log
    else
      #the process completed successfully
    printf "\n###############\n>Single read: $1 bp:$2 depth:$3 error:$4 :\n" >> ../report.txt
      raw_n50 fmdef.p5.fq.gz >> ../report.txt
    fi

  else
    echo "Failed to execute sim reads for $1 $2 read length $3 depth $4 error $5" >> ../sim_reads_errors.log
  fi
  popd  
}

handle_paired_reads ()
{
  pushd "$1"
  sim_reads "$input_file" sim_reads.fa --read_length $3 --depth $4 --error_rate $5 --paired >> ../sim_reads.log

  #check if file is empty
  if [ -s sim_reads.fa ]; then
    #use idba_ud
    idba_ud -r sim_reads.fa -o idba_ud
    printf "\n###############\n>Paired read: $1 bp:$2 depth:$3 error:$4 :\n" >> ../report.txt
    raw_n50 idba_ud/contig.fa >> ../report.txt
  else
    echo "Failed to execute sim reads for $1 $2 read length $3 depth $4 error $5" >> ../sim_reads_errors.log
  fi
  popd  
}
#
# method calls
validate_input
setup

printf "Done :) \n"

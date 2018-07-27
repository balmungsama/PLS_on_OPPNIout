#!/bin/bash
#SBATCH -c 4            # Number of CPUS requested. If omitted, the default is 1 CPU.
#SBATCH --mem=10240     # Memory requested in megabytes. If omitted, the default is 1024 MB.
#SBATCH --time=7-0:0:0  # --time=days-hours:minutes:seconds 		Default is 3 hours.

filename=$1

top_dir=$(dirname $filename)
file=$(basename $filename)

echo filename = $filename
echo top_dir = $top_dir
echo file = $file

# if [ ${#TOPDIR[@]} == 1 ]; then
# 	top_dir=$(pwd)
# fi 

echo 'Running PLS anlalysis...'

matlab -nodesktop -nosplash -r "pls_file='$file';pls_path='$top_dir';run('/global/home/hpc3586/JE_packages/PLS_on_OPPNIout/run_PLS_analysis.m')"

echo 'Finished.'

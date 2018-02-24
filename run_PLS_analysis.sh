#!/bin/bash
#SBATCH -c 4            # Number of CPUS requested. If omitted, the default is 1 CPU.
#SBATCH --mem=10240     # Memory requested in megabytes. If omitted, the default is 1024 MB.

filename=$1

echo filename = $filename

TOP_DIR=$(dirname $filename)
FILE=$(basename $filename)

if [ ${#TOPDIR[@]} == 1 ]; then
	TOP_DIR=$(pwd)
fi 

echo 'Running PLS anlalysis...'

matlab -nodesktop -nosplash -r "pls_file='$FILE';pls_path='$TOP_DIR';run('/global/home/hpc3586/JE_packages/PLS_on_OPPNIout/run_PLS_analysis.m')"

echo 'Finished.'
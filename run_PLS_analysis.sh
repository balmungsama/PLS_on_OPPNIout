#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -M hpc3586@localhost
#$ -m be
#$ -q abaqus.q

filename=$1

TOP_DIR=$(dirname $filename)
FILE=$(basename $filename)

if [ ${#TOPDIR[@]} == 1 ]; then
	TOP_DIR=$(pwd)
fi 

echo 'Running PLS anlalysis...'

matlab -nodesktop -nosplash -r "pls_file='$FILE';pls_path='$TOP_DIR';run('/home/hpc3586/JE_packages/PLS_on_OPPNIout/run_PLS_analysis.m')"

echo 'Finished.'
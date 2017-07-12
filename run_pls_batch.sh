#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -M hpc3586@localhost
#$ -m be
#$ -q abaqus.q
#$ -o logs/run_erfmri_batch.out
#$ -e logs/run_erfmri_batch.err

echo '	running batch PLS job'

OUTPUT=$1
pls_batch_file=$2

##### accept arguments ##### 
while getopts o:f: option; do
	case "${option}"
	in
		o) OUTPUT=${OPTARG};;
		f) FILE=${OPTARG};;
		\?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
	esac
done

matlab -r "OUTPUT='$OUTPUT';pls_batch_file='$FILE';run('/home/hpc3586/JE_packages/PLS_on_OPPNIout/run_pls_batch.m')" -nodesktop -nosplash

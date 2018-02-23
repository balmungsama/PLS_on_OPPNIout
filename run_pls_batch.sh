#!/bin/bash
#SBATCH -c 4            # Number of CPUS requested. If omitted, the default is 1 CPU.
#SBATCH --mem=10240     # Memory requested in megabytes. If omitted, the default is 1024 MB.
#SBATCH -t 0-1:0:0      # How long will your job run for? If omitted, the default is 3 hours.

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

matlab -r "OUTPUT='$OUTPUT';pls_batch_file='$FILE';run('/global/home/hpc3586/JE_packages/PLS_on_OPPNIout/run_pls_batch.m')" -nodesktop -nosplash

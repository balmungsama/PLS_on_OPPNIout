#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -M hpc3586@localhost
#$ -m be
#$ -q abaqus.q
#$ -o logs/write_erfmri_analysis.out
#$ -e logs/write_erfmri_analysis.err

##### accept arguments ##### 
while getopts i:o:p:b:w:a:f:s:r:n:t:z:hc: option; do
	case "${option}"
	in
		i) OPPNI_DIR=${OPTARG};;    # path to the PLS package
		h) echo "$usage" >&2
			 exit 1
			 ;;
		c) seed=${OPTARG}
       ;;
		# :) printf "missing argument for -%s\n" "$OPTARG" >&2
    #    echo "$usage" >&2
    #    exit 1
		# 	 ;;
		\?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
	esac
done

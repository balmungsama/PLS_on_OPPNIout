#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -M hpc3586@localhost
#$ -m be
#$ -q abaqus.q
#$ -o logs/write_erfmri_analysis.out
#$ -e logs/write_erfmri_analysis.err

SCRIPT_DIR='/home/hpc3586/JE_packages/PLS_on_OPPNIout'

##### accept arguments ##### 
while getopts p:b:v:g:f:r:t:m:c:w:x:y:z:q:s:d:e: option; do
	case "${option}"
	in
		p) PATH=${OPTARG};;
		b) BEHAV_DIR=${OPTARG};;
		v) VARBS=${OPTARG};;
		g) GROUPS=${OPTARG};;
		f) PREFIX=${OPTARG};;
		r) RM_OUT=${OPTARG};;
		t) PLS_opt=${OPTARG};;
		m) MEAN_type=${OPTARG};;
		c) COR_mode=${OPTARG};;

		w) num_perm=${OPTARG};;
		x) num_split=${OPTARG};;
		y) num_boot=${OPTARG};;
		z) boot_type=${OPTARG};;

		q) clim=${OPTARG};;

		s) save_data=${OPTARG};;

		d) CONTRASTS=${OPTARG};;
		e) CONDS=${OPTARG};;

		\?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
	esac
done

Rscript.bak $SCRIPT_DIR/write_analysis.R --PATH=$PATH --BEHAV_DIR=$BEHAV_DIR --VARBS=$VARBS --GROUPS=$GROUPS --PREFIX=$PREFIX --RM_OUT=$RM_OUT --PLS_opt=$PLS_opt --MEAN_type=$MEAN_type --COR_mode=$COR_mode --num_perm=$num_perm --num_split=$num_split --num_boot=$num_boot --clim=$clim --save_data=$save_data --CONTRASTS==$CONTRASTS --CONDS=$CONDS
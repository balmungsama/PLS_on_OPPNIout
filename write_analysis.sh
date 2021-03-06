#!/bin/bash
#SBATCH -c 4            # Number of CPUS requested. If omitted, the default is 1 CPU.
#SBATCH --mem=10240     # Memory requested in megabytes. If omitted, the default is 1024 MB.
#SBATCH -t 0-4:0:0      # How long will your job run for? If omitted, the default is 3 hours.

SCRIPT_DIR='/global/home/hpc3586/JE_packages/PLS_on_OPPNIout'

##### accept arguments ##### 
while getopts p:b:v:g:f:r:t:m:c:w:x:y:z:q:s:d:e:l: option; do
	case "${option}"
	in
		p) IN_PATH=${OPTARG};;
		b) BEHAV_DIR=${OPTARG};;
		v) VARBS=${OPTARG};;
		g) GROUP_LS=${OPTARG};;
		f) PREFIX=${OPTARG};;
		r) RM_CLEAN=${OPTARG};;
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
		l) REMOVE_LS=${OPTARG};;

		\?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
	esac
done

echo '	%%% VARIABLES %%%'
echo IN_PATH   = $IN_PATH   
echo BEHAV_DIR = $BEHAV_DIR 
echo VARBS     = $VARBS     
echo GROUP_LS  = $GROUP_LS    
echo PREFIX    = $PREFIX    
echo RM_CLEAN  = $RM_CLEAN    
echo PLS_opt   = $PLS_opt   
echo MEAN_type = $MEAN_type 
echo COR_mode  = $COR_mode  
echo num_perm  = $num_perm  
echo num_split = $num_split 
echo num_boot  = $num_boot  
echo boot_type = $boot_type 
echo clim      = $clim      
echo save_data = $save_data 
echo CONTRASTS = $CONTRASTS 
echo CONDS     = $CONDS     
echo REMOVE_LS = $REMOVE_LS 
echo ' '


Rscript $SCRIPT_DIR/write_analysis.R --PATH=$IN_PATH --BEHAV_DIR=$BEHAV_DIR --VARBS=$VARBS --GROUPS=$GROUP_LS --PREFIX=$PREFIX --RM_CLEAN=$RM_CLEAN --PLS_opt=$PLS_opt --MEAN_type=$MEAN_type --COR_mode=$COR_mode --num_perm=$num_perm --num_split=$num_split --num_boot=$num_boot --clim=$clim --save_data=$save_data --CONTRASTS=$CONTRASTS --CONDS=$CONDS --REMOVE_LS=$REMOVE_LS
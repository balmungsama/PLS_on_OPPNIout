#!/bin/bash
#SBATCH -c 4            # Number of CPUS requested. If omitted, the default is 1 CPU.
#SBATCH --mem=10240     # Memory requested in megabytes. If omitted, the default is 1024 MB.
#SBATCH -t 0-4:0:0      # How long will your job run for? If omitted, the default is 3 hours.

SCRIPT_DIR='/global/home/hpc3586/JE_packages/PLS_on_OPPNIout'

##### accept arguments ##### 
while getopts p:b:v:g:f:r:t:m:c:w:x:y:z:q:s:d:e:l: option; do
	case "${option}"
	in
		p) IN_PATH=$(echo ${OPTARG});;
		b) BEHAV_DIR=$(echo ${OPTARG});;
		v) VARBS=$(echo ${OPTARG});;
		g) GROUPS=$(echo ${OPTARG});;
		f) PREFIX=$(echo ${OPTARG});;
		r) RM_OUT=$(echo ${OPTARG});;
		t) PLS_opt=$(echo ${OPTARG});;
		m) MEAN_type=$(echo ${OPTARG});;
		c) COR_mode=$(echo ${OPTARG});;

		w) num_perm=$(echo ${OPTARG});;
		x) num_split=$(echo ${OPTARG});;
		y) num_boot=$(echo ${OPTARG});;
		z) boot_type=$(echo ${OPTARG});;

		q) clim=$(echo ${OPTARG});;

		s) save_data=$(echo ${OPTARG});;

		d) CONTRASTS=$(echo ${OPTARG});;
		e) CONDS=$(echo ${OPTARG});;
		l) REMOVE_LS=$(echo ${OPTARG});;

		\?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
	esac
done

echo $IN_PATH   
echo $BEHAV_DIR 
echo $VARBS     
echo $GROUPS    
echo $PREFIX    
echo $RM_OUT    
echo $PLS_opt   
echo $MEAN_type 
echo $COR_mode  
echo $num_perm  
echo $num_split 
echo $num_boot  
echo $boot_type 
echo $clim      
echo $save_data 
echo $CONTRASTS 
echo $CONDS     
echo $REMOVE_LS 


Rscript $SCRIPT_DIR/write_analysis.R --PATH=$IN_PATH --BEHAV_DIR=$BEHAV_DIR --VARBS=$VARBS --GROUPS=$GROUPS --PREFIX=$PREFIX --RM_OUT=$RM_OUT --PLS_opt=$PLS_opt --MEAN_type=$MEAN_type --COR_mode=$COR_mode --num_perm=$num_perm --num_split=$num_split --num_boot=$num_boot --clim=$clim --save_data=$save_data --CONTRASTS=$CONTRASTS --CONDS=$CONDS --REMOVE_LS=$REMOVE_LS
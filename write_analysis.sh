#!/bin/bash
#SBATCH -c 4            # Number of CPUS requested. If omitted, the default is 1 CPU.
#SBATCH --mem=10240     # Memory requested in megabytes. If omitted, the default is 1024 MB.
#SBATCH -t 0-4:0:0      # How long will your job run for? If omitted, the default is 3 hours.

SCRIPT_DIR='/global/home/hpc3586/JE_packages/PLS_on_OPPNIout'

##### accept arguments #####
while getopts p:b:v:g:f:t:m:c:w:x:y:z:q:s:d:e:l:a: option; do
	case "${option}"
	in
		p) IN_PATH=${OPTARG};;
			# path to directory containing *sessiondata.mat files
		b) BEHAV_FILE=${OPTARG};;
			# path to directory containing behavioural data, stored in subj-specific *.mat files
		v) VARBS=${OPTARG};;
			# names of behavioural variables to use in the analysis
		g) GROUPS=${OPTARG};;
			# list of groups to use in the analysis
		f) PREFIX=${OPTARG};;
			# prefix of sessiondata files to include
		t) PLS_opt=${OPTARG};;
			# 1. Mean-Centering PLS
			# 2. Non-Rotated Task PLS (please also fill out contrast data below)
			# 3. Regular Behav PLS (please also fill out behavior data & name below)
			# 4. Multiblock PLS (please also fill out behavior data & name below)
			# 5. Non-Rotated Behav PLS (please also fill out contrast data and behavior data & name below)
			# 6. Non-Rotated Multiblock PLS (please also fill out contrast data and behavior data & name below)
		m) MEAN_type=${OPTARG};;
			# 0. Remove group condition means from conditon means within each group
			# 1. Remove grand condition means from each group condition mean
			# 2. Remove grand mean over all subjects and conditions
			# 3. Remove all main effects by subtracting condition and group means
		c) COR_mode=${OPTARG};;
			# 0. Pearson correlation
			# 2. covaraince
			# 4. cosine angle
			# 6. dot product
		w) num_perm=${OPTARG};;
			# number of permutations
		x) num_split=${OPTARG};;
			# number of split-half resampling iterations to run
		y) num_boot=${OPTARG};;
			# number of bootstrap resamples
		z) boot_type=${OPTARG};;
			# either strat or nonstrat bootstrap type
		q) clim=${OPTARG};;
			# confidence level for behav PLS
		s) save_data=${OPTARG};;
			# set to 1 to save stacked datamat
		d) CONTRASTS=${OPTARG};;
			# contrasts to run, separated by |, ;, or :
		e) CONDS=${OPTARG};;
			# conditions to use
		l) REMOVE_LS=${OPTARG};;
			# list of participants/files to exclude from the anlaysis
		a) indep_runs=${OPTARG};;
			# should each repeated run be treated independently? T or F

		\?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
	esac
done

echo '	%%% VARIABLES %%%'
echo IN_PATH    = $IN_PATH
echo BEHAV_FILE = $BEHAV_FILE
echo VARBS      = $VARBS
echo GROUPS     = $GROUPS
echo PREFIX     = $PREFIX
echo PLS_opt    = $PLS_opt
echo MEAN_type  = $MEAN_type
echo COR_mode   = $COR_mode
echo num_perm   = $num_perm
echo num_split  = $num_split
echo num_boot   = $num_boot
echo boot_type  = $boot_type
echo clim       = $clim
echo save_data  = $save_data
echo CONTRASTS  = $CONTRASTS
echo CONDS      = $CONDS
echo REMOVE_LS  = $REMOVE_LS
echo indep_runs = $indep_runs
echo ' '


Rscript $SCRIPT_DIR/write_analysis.R --PATH=$IN_PATH --BEHAV_FILE=$BEHAV_FILE --VARBS=$VARBS --GROUPS=$GROUPS --PREFIX=$PREFIX --RM_CLEAN=$RM_CLEAN --PLS_opt=$PLS_opt --MEAN_type=$MEAN_type --COR_mode=$COR_mode --num_perm=$num_perm --num_split=$num_split --num_boot=$num_boot --clim=$clim --save_data=$save_data --CONTRASTS=$CONTRASTS --CONDS=$CONDS --REMOVE_LS=$REMOVE_LS --indep_runs=$indep_runs
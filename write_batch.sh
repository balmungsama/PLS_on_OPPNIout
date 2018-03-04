#!/bin/bash
#SBATCH -c 4            # Number of CPUS requested. If omitted, the default is 1 CPU.
#SBATCH --mem=1024      # Memory requested in megabytes. If omitted, the default is 1024 MB.

# TODO: make this extract the CON/FIX/IND optimized data instead of the un-preprocessed input

##### matlab plugins #####

# MAT_PLUGINS='/home/hpc3586/matlab_plugins'

# ##### installation directory #####
# INSTALL_DIR='/home/hpc3586/JE_packages/PLS_on_OPPNIout' # enter in the directory in which the package is stored
# cd $INSTALL_DIR                                         # cd to the install directory

##### Default values #####
 
WIN_SIZE=8
NORMAL=0
REF_NUM=1

##### get help Documentation text #####

# usage=$(cat write_batch_Documentation.txt)

##### accept arguments ##### 
while getopts i:o:p:b:w:a:f:s:r:n:t:z:m:h:c: option; do
	case "${option}"
	in
		i) OPPNI_DIR=${OPTARG};;     # path to oppni-preprocessed data
		o) OUTPUT=${OPTARG};;        # place to output the PLS files
		p) PREFIX=${OPTARG};;        # prefix for the session file & datamat file
		b) BRAIN_ROI=${OPTARG};;     # brain roi (can be number or file path to a mask)
		w) WIN_SIZE=${OPTARG};;      # temporal window size in scans
		a) ACROSS_RUN=${OPTARG};;    # for merge data across all run, 0 for within each run
		f) NORM_REF=${OPTARG};;      # 1 for single subject analysis, 0 for normal analysis
		s) SINGLE_SUBJ=${OPTARG};;   # 1 for single subject analysis, 0 for normal analysis
		r) REF_ONSET=${OPTARG};;     # reference scan onset for all conditions
		n) REF_NUM=${OPTARG};;       # number of reference scans for all conditions
		t) NORMAL=${OPTARG};;        # normalize volume mean (keey 0 unless necessary)
		z) RUN=${OPTARG};;           # do you want to run the analysis after the creation of the file? ('true or false')
		m) MERGE_RUNS=${OPTARG};;    # Do you want a seperate batch file for each run (0), or all runs to be within a single batch (1)?
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


##### test variables #####

# OPPNI_DIR='/mnt/c/Users/john/Desktop/practice_PLS/GO_sart_old_erCVA_JE.txt'  
# OUTPUT='/mnt/c/Users/john/Desktop/practice_PLS/PLS_results'

##### create output directories #####

mkdir -p $OUTPUT

##### check OS #####

detect_OS=$(uname -r)

if [[ $detect_OS =~ 'Microsoft' ]]; then
	OS=windows
	matlab='matlab.exe'
else
	OS=unix
	matlab='matlab'
fi

##### define function to change Unix-style paths to Windows-style
function lin2win {

	if [ $OS != 'windows' ]; then
		exit
	fi

	conv_path=$1

	conv_path=${conv_path//'/mnt/'/ }

	conv_path=(${conv_path//'/'/ })

	conv_count=0
	conv_path_new=''
	for dir in ${conv_path[@]}; do
		

		if (( conv_count == 0 )); then
			dir=${dir^^}:
			split=''
		else
			split='\'
		fi

		# echo count=$conv_count, dir is '"'$dir'"'
		
		conv_path_new=$conv_path_new$split$dir

		conv_count=$(($conv_count + 1))
	done


	# echo $conv_path
	echo $conv_path_new
}

if [ $OS == "windows" ]; then
	OPPNI_DIR=$(lin2win $OPPNI_DIR)
fi

##### prep arguments for passage into Matlab #####

mOS=$(echo "OS='$OS'")
mOPPNI_DIR=$(echo "OPPNI_DIR='$OPPNI_DIR'")
mOUTPUT=$(echo "OUTPUT='$OUTPUT'")
mPREFIX=$(echo "PREFIX='$PREFIX'")
mBRAIN_ROI=$(echo "BRAIN_ROI='$BRAIN_ROI'")
mWIN_SIZE=$(echo "WIN_SIZE='$WIN_SIZE'")
mACROSS_RUN=$(echo "ACROSS_RUN='$ACROSS_RUN'")
mNORM_REF=$(echo "NORM_REF='$NORM_REF'")
mSINGLE_SUBJ=$(echo "SINGLE_SUBJ='$SINGLE_SUBJ'")
mREF_ONSET=$(echo "REF_ONSET='$REF_ONSET'")
mREF_NUM=$(echo "REF_NUM='$REF_NUM'")
mNORMAL=$(echo "NORMAL='$NORMAL'") 
mRUN=$(echo "RUN=$RUN")
mMERGE_RUNS=$(echo "MERGE_RUNS=$MERGE_RUNS")


mREAD_SUBJMAT=$(echo "run('$INSTALL_DIR/read_subjmat.m')")

mCOMMANDS=$(echo "$mOS;$mOPPNI_DIR;$mOUTPUT;$mPREFIX;$mBRAIN_ROI;$mWIN_SIZE;$mACROSS_RUN;$mNORM_REF;$mSINGLE_SUBJ;$mREF_ONSET;$mREF_NUM;$mNORMAL;$mRUN;$mMERGE_RUNS;$mREAD_SUBJMAT")

# echo $mCOMMANDS
cd $OUTPUT
echo 'Creating batch files...'
$matlab -r "$mCOMMANDS" -nosplash -nodesktop 
echo 'DONE'

echo ' '

if [[ $RUN == 'true' ]]; then
	echo 'Running batch_plsgui...'
	$matlab -r "$mPREFIX;$mOUTPUT;run('$INSTALL_DIR/run_subjmat.m')" -nosplash -nodesktop
	echo 'DONE'
fi
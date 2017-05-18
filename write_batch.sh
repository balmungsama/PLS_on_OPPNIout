#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -M hpc3586@localhost
#$ -m be
#$ -o logs/grp_STD.out
#$ -e logs/grp_STD.err
#$ -q abaqus.q
#$ -o logs/write_erfmri_batch.out
#$ -e logs/write_erfmri_batch.err

# TODO: make this extract the CON/FIX/IND optimized data instead of the un-preprocessed input

##### installation directory #####
INSTALL_DIR='/home/hpc3586/JE_packages/PLS_on_OPPNIout' # enter in the directory in which the package is stored
cd $INSTALL_DIR                                         # cd to the install directory

##### Default values #####
 
WIN_SIZE=8
NORMAL=0
RUN=false
REF_NUM=1
BRAIN_ROI=0.15

##### get help Documentation text #####

usage=$(cat Documentation.txt)

##### accept arguments ##### 
while getopts i:o:p:b:w:a:f:s:r:n:t:z:hc: option; do
	case "${option}"
	in
		i) OPPNI_DIR=${OPTARG};;    # path to the PLS package
		o) OUTPUT=${OPTARG};;        # place to output the PLS files
		p) PREFIX=${OPTARG};;        # prefix for the session file & datamat file
		b) BRAIN_ROI=${OPTARG};;     # brain roi (can be number or file path to a mask)
		w) WIN_SIZE=${OPTARG};;      # temporal window size in scans
		a) ACROSS_RUN=${OPTARG};;    # for merge data across all run, 0 for within each run
		f) NORM_REF=${OPTARG};;      # for single subject analysis, 0 for normal analysis
		s) SINGLE_SUBJ=${OPTARG};;   # 1 for single subject analysis, 0 for normal analysis
		r) REF_ONSET=${OPTARG};;     # reference scan onset for all conditions
		n) REF_NUM=${OPTARG};;       # number of reference scans for all conditions
		t) NORMAL=${OPTARG};;        # normalize volume mean (keey 0 unless necessary)
		z) RUN=${OPTARG};;           # do you want to run the analysis after the creation of the file? ('true or false')
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

# echo RUN = $RUN
# echo mOPPNI_DIR
mREAD_SUBJMAT=$(echo "run('read_subjmat.m')")

mCOMMANDS=$(echo "$mOS;$mOPPNI_DIR;$mOUTPUT;$mPREFIX;$mBRAIN_ROI;$mWIN_SIZE;$mACROSS_RUN;$mNORM_REF;$mSINGLE_SUBJ;$mREF_ONSET;$mREF_NUM;$mNORMAL;$mRUN;$mREAD_SUBJMAT")

# echo $mCOMMANDS
$matlab -r "$mCOMMANDS" -nosplash -nodesktop -nosoftwareopengl #-wait 
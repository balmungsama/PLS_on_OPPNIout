##### log #####

#TODO add PLS package to Matlab path
#TODO check if any variables are undefined
#TODO get PLS_PATH to convert between Windows & Linux-style directory structure
#TODO add brain region

##### accept arguments #####

while getopts t:d:o:n:p:pre:win: option; do
        case "${option}"
        in
                t) TYPE=${OPTARG};;            # type of PLS to run
                d) DIR=${OPTARG};;             # group directory
                o) OUTPUT=${OPTARG};;          # directory to output results
                n) NAME_OUT=${OPTARG};;        # name to give teh output files
								p) PLS_PATH=${OPTARG};;        # path to the PLS package
								pre) PREFIX=${OPTARG};;        # prefix for the session file & datamat file
								win) WIN_SIZE=${OPTARG};;      # temporal window size in scans
								arun) ACROSS_RUN=${OPTARG};;   # for merge data across all run, 0 for within each run
								ssubj) SINGLE_SUBJ=${OPTARG};; # 1 for single subject analysis, 0 for normal analysis
								refon) REF_ONSER=${OPTARG};;   # reference scan onset for all conditions
								nref) NUM_REFS=${OPTARG};;     # number of reference scans for all conditions
								conds) NUM_CONDS=${OPTARG};;   # number of conditions to use in analysis
        esac
done

##### test variables #####

PLS_PATH='/mnt/c/Users/john/Desktop/practice_PLS/output/GO/Older/noCustomReg_GO_sart_old_erCVA_JE_erCVA/'
OUTPUT='/mnt/c/Users/john/Desktop/practice_PLS/PLS_results'

##### create output directories #####

mkdir $OUTPUT
mkdir $OUTPUT/tmp

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

# cd $PLS_PATH

subj_count=0
( cat $PLS_PATH/input_file.txt; echo; ) | while read subj_line; do

	subj_line=($subj_line)
	subj_line=${subj_line[1]}
	subj_line=(${subj_line//'='/ })
	subj_line=${subj_line[1]}

	subj_line=$(basename $subj_line)
	subj_line=$(echo ${subj_line%.*})
	
	if (( $subj_count == 0 )); then
		echo $subj_line >  $OUTPUT/tmp/subj_ls.txt 
	else
		echo $subj_line >> $OUTPUT/tmp/subj_ls.txt 
	fi
	
	subj_count=$(( $subj_count + 1 ))

done 

##### create batch text file #####

( cat $OUTPUT/tmp/subj_ls.txt ; echo; ) | while read subj; do
	
	if (( ${#subj} > 0)); then

		split_info=$PLS_PATH/'intermediate_processed/split_info/'$subj.mat
		split_info=$(lin2win $split_info)
		echo $split_info

		$matlab -r "split_info=load(""'"$split_info"'"");run('read_subjmat.m')" # -nodesktop -nosplash 

	fi
	
done 



# $matlab -nodesktop -nosplash -r "PLS=$PLS_PATH;run('run_PLS.m')" #-wait # -r path/to/matlab/script.m 

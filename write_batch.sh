##### log #####

#TODO add PLS package to Matlab path
#TODO check if any variables are undefined
#TODO get INPUT_FILE to convert between Windows & Linux-style directory structure
#TODO add brain region

##### accept arguments #####

while getopts t:d:o:n:p:pre:win: option; do
        case "${option}"
        in
                t) TYPE=${OPTARG};;            # type of PLS to run
                d) DIR=${OPTARG};;             # group directory
                o) OUTPUT=${OPTARG};;          # directory to output results
                n) NAME_OUT=${OPTARG};;        # name to give teh output files
								p) INPUT_FILE=${OPTARG};;        # path to the PLS package
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

INPUT_FILE='/mnt/c/Users/john/Desktop/practice_PLS/GO_sart_old_erCVA_JE.txt'  #TODO only needs to be the input file
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

if [ $OS == "windows" ]; then
	INPUT_FILE=$(lin2win $INPUT_FILE)
fi

$matlab -r "fileID=fopen('"$INPUT_FILE"');OUTPUT=""'$OUTPUT';run('read_subjmat.m')" -wait # -nodesktop -nosplash 
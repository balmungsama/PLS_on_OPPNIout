filename=$1

TOP_DIR=$(dirname $filename)
FILE=$(basename $filename)

if [ ${#TOPDIR[@]} == 1 ]; then
	TOP_DIR=$(pwd)
fi 

echo 'Running PLS anlalysis...'

matlab -nodesktop -nosplash -r "pls_file='$FILE';pls_path='$TOP_DIR';run('run_PLS_anlaysis.m')"

echo 'Finished.'
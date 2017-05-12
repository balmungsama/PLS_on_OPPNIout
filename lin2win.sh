detect_OS=$(uname -r)

if [[ $detect_OS =~ 'Microsoft' ]]; then
	OS=windows
	matlab='matlab.exe'
else
	OS=unix
	matlab='matlab'
fi

if [ $OS != 'windows' ]; then
	conv_path=$1
	echo $conv_path
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

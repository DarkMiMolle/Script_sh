#! /bin/sh

RED="\033[31m"
GREEN="\033[32m"
BOLD="\033[1m"
UNDERLINE="\033[4m"
BLINKING="\033[5m"
NORMAL="\033[0m"

Usage="./push [-r remote_name][-t <continue>=N][--tag <tagname>][-h\--help]"

opt_kind=""
remote=""
testsuit=""
tag=""
help=""
#help_msg="
#	$Usage\n
 #    \n
 #    -r        :    also push on 'remote_name'.\n
 #    \n
 #    -t        :    execute a make check and stop if 'continue' is set to N.\n
 #                   continue if 'continue' is set to  Y.\n
 #    \n
 #    --tag     :    set the tag 'tagname' (for now tagname is optional)\n
 #    \n
	# -h        :    display that help"

for arg in $@; do
	if [[ $arg == "-h" || $arg == "--help" ]]; then
		help="$arg"

	elif [[ $arg == "-r" && $remote == "" ]]; then
		opt_kind="remote"

	elif [[ $arg == "-t" && $testsuit == "" ]]; then
		opt_kind="testsuit"
		testsuit="N"

	elif [[ $arg == "--tag" && $tag == "" ]]; then
		opt_kind="tag"

	elif [[ $opt_kind == "remote" ]]; then
		remote="$arg"
		opt_kind=""

	elif [[ $opt_kind == "testsuit" ]]; then
		if [ $arg != "N" -a $arg != "Y" ]; then
			echo "Fail Usage: $Usage" >&2
			echo "option -t can be followed by Y or N and is set to N by default" >&2
		else
			testsuit=$arg
		fi
		opt_kind=""

	elif [[ $opt_kind == "tag" ]]; then
		tag="$arg"
		opt_kind=""

	else
		echo "Fail Usage: $Usage\n" >&2
		echo "$arg is not an option or is allready set" >&2
		echo "here are the options used:"
		if [[ $remote != "" ]]; then
			echo "-r : $remote"
		fi

		if [[ $testsuit != "" ]]; then
			echo "-t : $testsuit"
		fi

		if [[ $tag != "" ]]; then
			echo "--tag : $tag"
		fi
		if [[ $help != "" ]]; then
			echo "$help"
		fi
		exit 3
	fi
done
if [[ $help != "" ]]; then
	echo "$Usage"
    echo ""
    echo "-r        :    also push on 'remote_name'."
    echo ""
    echo "-t        :    execute a make check and stop if 'continue' is set to N.\n
                   continue if 'continue' is set to  Y."
    echo ""
    echo "--tag     :    set the tag 'tagname' (for now tagname is optional)."
    echo ""
	echo "-h        :    display that help"
	exit 0
fi
mkdir .__tmp_push__
make
make 2> .__tmp_push__/error
if [[ `cat .__tmp_push__/error` != "" ]]; then
	echo ""
	echo "$RED$BOLD$BLINKING!\tMAKE FAILE\t!$NORMAL"
	exit 1
else
	clear
	resume="$GREEN$BOLD\tCompile OK$NORMAL"
	if [[ testsuit != "" ]]; then
		make check 2>.__tmp_push__/error
		clear
		make check
		if [[ `cat .__tmp_push__/error` != "" ]]; then
			resume="$resume\n$RED$BOLD$BLINKING!\tMAKE CHECK FAIL \t!$NORMAL"
			if [[ $testsuit == "N" ]]; then
				echo "\n$resume"
				exit 2
			fi
		else
			resume="$resume\n$GREEN$BOLD\tmake check OK$NORMAL"
			testsuit="OK"
		fi	
	fi
	if [[ $testsuit == "OK" || $testsuit == "" || $testsuit == "Y" ]]; then
		clear
		echo "$resume"
		git push

		if [[ $tag == "" ]]; then
			echo "\n$BOLD$UNDERLINE Tag$NORMAL: "
			read tag
		fi
		git tag "$tag"
		git push --tags
		if [[ $remote != "" ]]; then
			git push "$remote" --tags	
		fi
	fi
fi
rm -r .__tmp_push__
exit 0
#! /bin/sh

check_opt_r() {
	if [ "$opt_kind" = "-r" ]; then
		echo "Fail Usage: $Usage"
		echo "$arg can not follow $opt_kind"
		exit 3
	fi
}

check_opt_tag() {
	if [ "$opt_kind" = "--tag" ]; then
		echo "Fail Usage: $Usage"
		echo "$arg can not follow $opt_kind"
		exit 3
	fi
}

RED="\033[31m"
GREEN="\033[32m"
BOLD="\033[1m"
UNDERLINE="\033[4m"
BLINKING="\033[5m"
NORMAL="\033[0m"

Usage="./push [-r remote_name ][-t <continue>=N ][--tag <tagname>][-f][-h\--help ]"

opt_kind="" 
remote=""
testsuit=""
tag=""
help=""
force=0
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
	if [ "$arg" = "-h" -o "$arg" = "--help" ]; then
		check_opt_r
		check_opt_tag
		help="$arg"

	elif [ "$arg" = "-f" ]; then
		check_opt_r
		check_opt_tag
		force=1

	elif [ "$arg" = "-r" -a "$remote" = "" ]; then
		check_opt_r
		check_opt_tag
		opt_kind="-r"

	elif [ "$arg" = "-t" -a "$testsuit" = "" ]; then
		check_opt_r
		check_opt_tag
		opt_kind="-t"
		testsuit="N"

	elif [ "$arg" = "--tag" -a "$tag" = "" ]; then
		check_opt_r
		check_opt_tag
		opt_kind="--tag"

	elif [ "$opt_kind" = "-r" ]; then
		remote="$arg"
		opt_kind=""

	elif [ "$opt_kind" = "-t" ]; then
		if [ "$arg" != "N" -a "$arg" != "Y" ]; then
			echo "Fail Usage: $Usage" >&2
			echo "option -t can be followed by Y or N and is set to N by default" >&2
			exit 3
		else
			testsuit=$arg
		fi
		opt_kind=""

	elif [ "$opt_kind" = "--tag" ]; then
		# if [ "${arg:0:1}" = "-" ]; then
		if [ "`echo "$arg" | cut -c1-2`" = "-" ]; then

			if [ "$arg" = "-no-tag" ]; then
				tag="-no-tag"
			else
				echo "$arg is not a valid tag.">&2
				exit 3
			fi
		else
			tag="$arg"
		fi
		opt_kind=""

	else
		echo "Fail Usage: $Usage\n" >&2
		echo "$arg is not an option or is allready set" >&2
		echo "here are the options used:"
		if [ -n "$remote" ]; then
			echo "-r : $remote"
		fi

		if [ -n "$testsuit" ]; then
			echo "-t : $testsuit"
		fi

		if [ -n "$tag" ]; then
			echo "--tag : $tag"
		fi
		if [ -n "$help" ]; then
			echo "$help"
		fi
		exit 3
	fi
done
if [ -n "$help" ]; then
	echo "$Usage"
  echo ""
    echo "-r        :    Also push on 'remote_name'."
    echo "--------------------------------------------------------------------------------"
    echo "-t        :    Execute a make check and stop if 'continue' is set to N."
    echo "          |    Continue if 'continue' is set to  Y."
    echo "--------------------------------------------------------------------------------"
    echo "--tag     :    Set the tag 'tagname' (for now tagname is optional)."
    echo "--------------------------------------------------------------------------------"
    echo "-f        :    Force the push."
	echo "          |    If anything fail it will clear the terminal but will still let"
	echo "          |      you know you faild."
	echo "--------------------------------------------------------------------------------"
	echo "-h        :    Display that help"
	exit 0
fi
mkdir .__tmp_push__
make
make 2> .__tmp_push__/error
make_res="$?"

if [ -n "`cat .__tmp_push__/error`" -o "$make_res" -ne 0 ]; then
	echo ""
	resume="$RED$BOLD$BLINKING!\tMAKE FAILE\t!$NORMAL"
	if [ $force -eq 0 ]; then
		echo "$resume"
		exit 1
	fi
	force=2
fi
if [ $force -ne 2 ]; then
	clear
	resume="$GREEN$BOLD\tCompile OK$NORMAL"	
fi
if [ -n "$testsuit" -a "$make_res" -eq 0 ]; then
	make check 2>.__tmp_push__/error
	clear
	make check
	if [ -n "`cat .__tmp_push__/error`" ]; then
		resume="$resume\n$RED$BOLD$BLINKING!\tMAKE CHECK FAIL \t!$NORMAL"
		if [ "$testsuit" = "N" ]; then
			echo "\n$resume"
			exit 2
		fi
	else
		resume="$resume\n$GREEN$BOLD\tmake check OK$NORMAL"
		testsuit="OK"
	fi	
elif [ -n "$testsuit" -a "$make_res" -ne 0 ]; then
	resume="$resume\n$RED$BOLD$BLINKING!\tMAKE CHECK IMPOSSIBLE \t!$NORMAL"
	if [ "$force" -eq 0 ]; then
		echo "$resume"
		exit 2
	else
		testsuit="Y"
	fi
fi
if [ "$testsuit" = "OK" -o "$testsuit" = "" -o "$testsuit" = "Y" ]; then
	clear
	echo "$resume"
	git push

	if [ "$tag" = "" ]; then
		echo "\n$BOLD$UNDERLINE Tag$NORMAL: "
		read tag
	fi
	if [ "$tag" != "-no-tag" ]; then
		git tag "$tag"
		git push --tags	
	fi
	if [ -n "$remote" ]; then
		git push "$remote"
		git push "$remote" --tags	
	fi
fi

rm -r .__tmp_push__
exit 0
#!/usr/bin/env fish
# Name: fish-tools
# Version: 1.6.1
# Copyright (c) 2016, Simen Strange Øya
# License: Modified BSD license
# https://github.com/dxlr8r/fish-tools/blob/master/LICENSE

# TODO:
# - replace IFS manipulation with | read -z
# - expand on fn2xargs, implement inheritance

# int tools

function inc -a int -d 'increments integer $argv[1]'
	echo -ns (echo -s $int+1 | bc)
end

function even -a int -d 'even int # prints 1 if int is even, else 0'
	return (echo -ns (echo -s $int%2 | bc))
end

# string tools

# DEPRECATED, use string length
function length -d 'length string # prints length of a string'
	echo -ns $argv[1] | wc -m | xargs printf "%u"
end

function repeat -a x string -d 'repeat x string # prints a string x times'
	if test $x -gt 0 # seq does weird things when seq <= 0
		set buffer ""

		for key in (seq $x)
			set buffer (echo -ns $buffer $string)
		end

		echo -ns $buffer
	end
end

function stripcomments -d 'stripcomments str # removes comments from str'
	set -l IFS ''
	# https://github.com/milosz/sed-octo-proctor/
	set -l sedf (echo '1 {;/^#!/ {;p;};};/^[\t\ ]*#/d;/\.*#.*/ {;/[\x22\x27].*#.*[\x22\x27]/ !{;:regular_loop;s/\(.*\)*[^\$]#.*/\1/;t regular_loop;};/[\x22\x27].*#.*[\x22\x27]/ {;:special_loop;s/\([\x22\x27].*#.*[^\x22\x27]\)#.*/\1/;t special_loop;};/\\#/ {;:second_special_loop;s/\(.*\\#.*[^\]\)#.*/\1/;t second_special_loop;};/$#/ {;:third_special_loop;s/\(.*$#.*[^$\]\)#.*/\1/;t third_special_loop;};}' | tr ';' '\n') # GNU sed supports ; BSD doesn't
	flattenl $argv | sed -e $sedf # $argv is set before set -l IFS
end

# list tools
function flatten -d 'flatten delim list # flattens a list'
	if test (count $argv) -ge 2
		if echo -ns $argv[1] | perl -ne 'exit 1 if not /^\x1f$/' # flatten2
			set delim $argv[2]
			set tail $argv[3]
			set list $argv[4..(count $argv)]
		else
			set delim $argv[1]
			set tail ''
			set list $argv[2..(count $argv)]
		end

		set listl (count $list)
		set counter 1

		for el in $list
			echo -ns $el

			if test (echo $counter) -lt $listl
				echo -ne $delim
			else
				echo -ne $tail
			end

			set counter (inc $counter)
		end
	else
		echo -ns ''
	end
end

function flatten2 -d 'flatten2 delim tail list # like flatten, but adds tail to end of output'
	if test (count $argv) -ge 3
		flatten (echo -nes '\x1f') $argv
    else
        echo -ns ''
    end
end

function flatten0 -d 'flatten0 list # flatten list with 0-byte as delimiter'
	flatten '\x00' $argv
end

function flattenl -d 'flattenl list # flatten list with newline as delimiter'
	flatten '\n' $argv
end

function flattens -d 'flattens list # flatten list with space as delimiter'
	flatten ' ' $argv
end

function flattenn -d 'flattenn list # flatten list with no delimiter'
	flatten '' $argv
end

alias fl0 flatten0
alias fll flattenl
alias fls flattens
alias fln flattenn

function list-search -d "list-search needle haystick # prints position of needle in haystack (list), if not found prints -1"
	set needle $argv[1]
	set haystack $argv[2..(count $argv)]

	for key in (seq (count $haystack))
		if test $needle = $haystack[$key]
			echo -ns $key
			return
		end
	end

	echo -ns -1
end

# shell tools

# DEPRECATED, use fish_realpath
function realpath -d 'realpath dir # as realpath in Linux but this works on all platforms with fish and perl'
	perl -e 'use Cwd; print Cwd::abs_path($_), "\n" foreach @ARGV;' $argv[1]
end

function status-out -d 'status-out cmd # executes appended cmd, then redirect $status to stdout'
	eval $argv > /dev/null ^&1
	echo $status
end

alias @1 status-out # @ is used as a sign for status, and 1 is the FD for stdout

# use with care, eval doesn't play well with quotation. stfu is safer
function mute -d 'mute cmd # executes appended cmd while redirecting stdout and stderr to /dev/null'
	eval $argv > /dev/null ^&1 # remember to double quote qoutes
	return $status
end

function stfu -d 'stfu(cmd) OR stfu(cmd ^&-) # discard stdout and or stderr (^&-) and return status'
	return $status
end

function fn-desc -a fn -d 'fn-help fn # prints the description of specified function'
	#functions $fn | head -1 | perl -ne '/^function\s+\S+\s+--description\s+'(.+)'$/ && print $1'
	functions $fn | head -1 | perl -ne '/^function\s+\S+\s+--description\s+(.+)$/ && print $1' | perl -pe 's/(^\')(.+?)(\'$)/$2/'
end

function sub -d 'sub cmd OR sub fn1,fn2 cmd# executes appended cmd while including functions defined outside it\'s scope'
	if test (count $argv) -eq 1
		set -l IFS ''
		#set cmd (printf '%s' $argv[1] | base64 -w0)
		set cmd (printf '%s' $argv[1])
	else if test (count $argv) -ge 2
		set -l fnl (string split ',' $argv[1])
		set -l fns (stripcomments (functions $fnl))
		set -l IFS ''
		set -l fnf (flattenl $fns)
		#set cmd (printf '%s' $fnf (printf '%b' '\n\n') $argv[2] | base64 -w0)
		set cmd (printf '%s' $fnf (printf '%b' '\n\n') $argv[2..(count $argv)])
	end

	set -l IFS ''
	#fish -c (printf '%s' $cmd | base64 -d)
	fish -c (printf '%s' $cmd)
end

function fn2xargs -d 'fn2xargs' -d 'fn2xargs # creates independent scripts for built in functions, for use with xargs'
	set -l f2xpath ~/.config/fish/fn2xargs
	if not test -e $f2xpath; mkdir -p $f2xpath; end
	for fn in (functions -n)
		set -l fnfile 'f2x'-$fn
		echo -e '#!'(which 'env')' fish\nsource '(status -f) > $f2xpath/$fnfile # header
		functions $fn >> $f2xpath/$fnfile # function
		echo $fn '$argv' >> $f2xpath/$fnfile # entry point
		chmod +x $f2xpath/$fnfile
	end
end

alias f2x fn2xargs

function heredoc -d 'heredoc script label # fish doesn\'t support heredoc, this is a dirty hack, use with care'
	set script (realpath $argv[1])
	set label $argv[2]
	set print -1

	for line in (cat $script)
		if test (echo $line | grep '^#'$label'$') # print label to label
			set print (math "$print*-1")
		else if test $print -eq 1
			echo $line | sed 's/^.//'
		end
	end
end

function stop -d 'stop # sends ctrl-c'
	kill -SIGHUP %self
end

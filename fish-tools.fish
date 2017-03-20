#!/usr/bin/env fish
# Name: fish-tools
# Version: 1.7.1
# Copyright (c) 2016, Simen Strange Øya
# License: Modified BSD license
# https://github.com/dxlr8r/fish-tools/blob/master/LICENSE

# TODO:
# - replace IFS manipulation with | read -z
# - expand on fn2xargs, implement inheritance

# int tools

function inc -a int -d 'increments integer $argv[1]'
	printf '%d' (echo -s $int+1 | bc)
end

function even -a int -d 'even int # prints 1 if int is even, else 0'
	return (printf '%d' (echo -s $int%2 | bc))
end

# string tools

# DEPRECATED, use string length
function length -d 'length string # prints length of a string'
	echo -ns $argv[1] | wc -m | xargs printf "%u"
end

function repeat -a x string -d 'repeat x string # prints a string x times'
	if test $x -gt 0 # seq does weird things when seq <= 0
		for int in (seq $x)
			echo -ns $buffer $string
		end
	end
end

function stripcomments -d 'stripcomments str # removes comments from str'
	# https://github.com/milosz/sed-octo-proctor/
	echo '1 {;/^#!/ {;p;};};/^[\t\ ]*#/d;/\.*#.*/ {;/[\x22\x27].*#.*[\x22\x27]/ !{;:regular_loop;s/\(.*\)*[^\$]#.*/\1/;t regular_loop;};/[\x22\x27].*#.*[\x22\x27]/ {;:special_loop;s/\([\x22\x27].*#.*[^\x22\x27]\)#.*/\1/;t special_loop;};/\\#/ {;:second_special_loop;s/\(.*\\#.*[^\]\)#.*/\1/;t second_special_loop;};/$#/ {;:third_special_loop;s/\(.*$#.*[^$\]\)#.*/\1/;t third_special_loop;};}' | tr ';' '\n' | read -lz sedf
	# GNU sed supports ; BSD doesn't
	printf '%s\n' $argv | sed -e $sedf # $argv is set before set -l IFS
end


# list tools
function flatten -d 'flatten delim list # flattens a list'
	if test (count $argv) -ge 2
		set delim $argv[1]
		printf "%s$delim" $argv[2..(count $argv)] | head -c-(echo -nes $delim | wc -c)
	else
		echo -ns ''
	end
end

function flatten2 -d 'flatten delim list # flattens a list'
	if test (count $argv) -ge 3
		set delim $argv[1]
		set tail  $argv[2]
		printf "%s$delim" $argv[3..(count $argv)] | head -c-(echo -nes $delim | wc -c)
		printf "%b" $tail
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

# or use "contains"
function list-search -d "list-search needle haystick # prints position of needle in haystack (list), if not found prints -1"
	if test (count $argv) -ge 2
		set needle $argv[1]
		set haystack $argv[2..(count $argv)]
		contains -i $needle $haystack; or echo -ns '-1'
	end
end

# shell tools

# DEPRECATED, use fish_realpath
function realpath -d 'realpath dir # as realpath in Linux but this works on all platforms with fish and perl'
	perl -e 'use Cwd; print Cwd::abs_path($_), "\n" foreach @ARGV;' $argv[1]
end

# TEST, eval doesn't play well with quotation, tried to fix with printf
function status-out -d 'status-out cmd # executes appended cmd, then redirect $status to stdout'
	eval (printf "'%s' " $argv) >&- ^&1
	echo $status
end

alias @1 status-out # @ is used as a sign for status, and 1 is the FD for stdout

# TEST, eval doesn't play well with quotation, tried to fix with printf
function mute -d 'mute cmd # executes appended cmd while redirecting stdout and stderr to /dev/null'
	eval (printf "'%s' " $argv) >&- ^&1
	return $status
end

# DEPRECATED, use mute
function old-mute -d 'mute cmd # executes appended cmd while redirecting stdout and stderr to /dev/null'
	eval $argv > /dev/null ^&1 # remember to double quote qoutes
	return $status
end

function stfu -d 'stfu(cmd) OR stfu(cmd ^&-) # discard stdout and or stderr (^&-) and return status'
	return $status
end

function fn-desc -a fn -d 'fn-help fn # prints the description of specified function'
	functions $fn | head -1 | perl -ne '/^function\s+\S+\s+--description\s+(.+)$/ && print $1' | perl -ne 'if (/(^\')(.+?)(\'$)/) { print $2."\n" } else { $_ =~ s/[\\\]{1}//g;  print $_."\n" }'
end

# WARNING, TEST, use with care. Should be reimplemented with read -z versus IFS
function sub -d 'sub cmd OR sub fn1,fn2 cmd # executes appended cmd while including functions defined outside it\'s scope'
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

function fn2xargs -d 'fn2xargs # creates independent scripts for built in functions, for use with xargs'
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

function heredoc -d "heredoc script label # fish doesn't support heredoc, this is a dirty hack, use with care"
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
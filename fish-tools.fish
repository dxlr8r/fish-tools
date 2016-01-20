#!/usr/bin/env fish
# Name: fish-tools
# Version: 1.0
# Copyright (c) 2015, Simen Strange Øya
# License: Modified BSD license
# https://github.com/dxlr8r/fish-tools/blob/master/LICENSE

# string tools
function length -d 'length string # prints length of a string'
	echo -ns $argv[1] | wc -m | xargs printf "%u"
end

function repeat -a x string -d 'repeat x string # x=times to repeat'
	
	if test $x -gt 0 # seq does weird things when seq <= 0
		set buffer ""
		
		for key in (seq $x)
			set buffer (echo -ns $buffer $string)
		end
		
		echo -ns $buffer
	end
end

# list tools
function flatten -d 'flatten delim list # flattens a list'
	set delim $argv[1]
	set list $argv[2..(count $argv)]

	for el in $list
		set out $out $el $delim
	end

	echo -ns $out
end

function flatten0 -d 'flatten list # flatten list with 0-byte as delimiter'
	echo -ens (flatten "\x00" $argv[1..(count $argv)]) # wrapped echo enable interpretation of backslash escapes
end

function flattenl -d 'flatten list # flatten list with newline as delimiter'
	echo -ens (flatten "\n" $argv[1..(count $argv)]) # wrapped echo enable interpretation of backslash escapes
end

function flattens -d 'flatten list # flatten list with space as delimiter'
	flatten " " $argv[1..(count $argv)]
end

function flattenn -d 'flatten list # flatten list with no delimiter'
	flatten "" $argv[1..(count $argv)]
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

function realpath -d 'realpath dir # as realpath in Linux but this works on all platforms with fish and perl'
	perl -e 'use Cwd; print Cwd::abs_path($_), "\n" foreach @ARGV;' $argv[1]                             
end

function status-out -d 'status-out cmd # executes appended cmd, then redirect $status to stdout'
	set cmd (flattens $argv[1..(count $argv)])
	eval $cmd > /dev/null ^&1
	echo $status
end

alias @1 status-out # @ is used as a sign for status, and 1 is the FD for stdout

function fn-desc -a fn -d 'fn-help fn # prints the description of specified fn'
	#funced -e cat $fn | head -1 | perl -ne '/^function\s+\S+\s+--description\s+'(.+)'$/ && print $1'
	funced -e cat $fn | head -1 | perl -ne '/^function\s+\S+\s+--description\s+(.+)$/ && print $1' | perl -pe 's/(^\')(.+?)(\'$)/$2/'
end
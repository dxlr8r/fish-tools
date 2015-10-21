#!/usr/bin/env fish

function status-out -d 'print $status to stdout'
	set cmd (flatten $argv[1..(count $argv)])
	eval $cmd > /dev/null ^&1
	echo $status
end
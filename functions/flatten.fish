#!/usr/bin/env fish

function flatten -d 'flattens a list'
	set list $argv[1..(count $argv)]
	#set out ""
	
	for el in $list
		set out $out $el " "
	end
	
	echo -ns $out
end
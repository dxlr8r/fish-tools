#!/usr/bin/env fish

function length -d 'returns length of a string'
	echo -ns $argv[1] | wc -m | xargs printf "%u"
end
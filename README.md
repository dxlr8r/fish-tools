# fish-tools

Scripting tools for the fish shell

## Why

If you feel like fish is lacking some basic functions this might be the library for you

## Installation

Download and put anywhere on your computer. If you want to use it from your shell add `source /path/fish-tools.fish` to `~/.config/fish/config.fish`. To use it from a script the script can get access to it through your fish user's enviroment, or you can add it as a source to the script, same as above `source /path/fish-tools.fish`.

## Usage

* string tools: 
	* `length string # prints length of a string`
	* `repeat x string # prints a string x times`
* list tools: 
	* `flatten delim list # flattens a list`
	* `flatten0 list # flatten list with 0-byte as delimiter` *alias `fl0`*
	* `flattenl list # flatten list with newline as delimiter` *alias `fll`*
	* `flattens list # flatten list with space as delimiter` *alias `fls`*
	* `flattenn list # flatten list with no delimiter` *alias `fln`*
	* `list-search needle haystick # prints position of needle in haystack (list), if not found prints -1`
* shell tools
	* `realpath dir # as realpath in Linux but this works on all platforms with fish and perl`
	* `status-out cmd # executes appended cmd, then redirect $status to stdout` *alias `@1`*
	* `fn-help fn # prints the description of specified function`

## License

Copyright © 2016 Simen Strange Øya

Distributed under the Modified BSD license
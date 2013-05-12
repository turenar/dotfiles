#!/bin/bash

IFS=' '
alias sort='LANG=C sort'

# if hashfile is not found, target almost all files (date has no mean)
[ -e $0.hash ] || touch -t 199001010000 $0.hash

# target all files newer than prev executed
# calculate md5sum
find -name '*.jpg' -newer $0.hash -print0 | xargs --no-run-if-empty -0 md5sum | sort > $0.hash.jnl

# merge hashfiles and make dup-hash filelist
sort -m $0.hash $0.hash.jnl | uniq -D -w 32 > $0.hash.tmp

# prepare for launching bazooka
exec 3< $0.hash.tmp
_oldh=
while read _hash _file 0<&3; do
	if [ "${_oldh}" = "${_hash}" ]; then
		# BOMB!!!!!
		echo "${_file}: del"
		rm "${_file}"
	else
		# he is not enemy
	fi
	_oldh=${_hash}
done
exec 3<&-

# record checked hash
mv $0.hash $0.hash.bak
cut -d' ' -f1 < $0.hash.jnl | sort - $0.hash.bak -m -u > $0.hash

#!/bin/sh
unset GENTOO_VM _vm _no_exec
_vm=sun-jdk-1.6

while true; do
	case $1 in
		-6) _vm=sun-jdk-1.6; shift; continue;;
		-7) _vm=oracle-jdk-bin-1.7; shift; continue;;
		-s) _no_exec=1; shift; continue;;
		-*) echo "[$(basename $0)] Invalid argument: $1">&2; exit 1;;
		*)  break;;
	esac
done

export GENTOO_VM=${_vm}
export JAVA_HOME=/usr/lib/jvm/${_vm}
export JDK_HOME=${JAVA_HOME}

if [ -z "${no_exec}" ]; then
	exec $@
fi

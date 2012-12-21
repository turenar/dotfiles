#!/bin/bash

MYNAME=`gettail $0`
MYTMPDIR="/tmp/${MYNAME}.$$"
INODELISTF="${MYTMPDIR}/inode.lst"
INODESORTF="${MYTMPDIR}/inode.sorted"
UNIQINODEF="${MYTMPDIR}/file.uniq"
HASHF="${MYTMPDIR}/md5sum"
HASHSORTF="${HASHF}.sorted"
DRYRUNMODE=
DEBUGMODE=
ALLFILEMODE=yes

STARTDATE=0
ENDDATE=0

function usage() {
  cat <<_EOM_ 1>&2
Usage:
  ${MYNAME} [options...]
Options:
  -h    Show this help
  -n    Dry run (no effects)
  -d    Debug mode (will echo lots information)
  -H    Processes inode-unique files (excluding hard-linked files)
        It may effect in a directory almost fulled by hard-linked files.
_EOM_
}

function calcdate(){
	local datediff
	let datediff="$2 - $1"
	echo "took ${datediff}sec" >&2
}

function destruct(){
	if [ -z "${DEBUGMODE}" ]; then
		echo "Removing temporary directory" >&2
		rm -rf ${MYTMPDIR}
	fi
	exit 0;
}

function countline(){
	local linecount=`wc -l $1 | cut -d ' ' -f1`
	echo -n "${linecount}files: " >&2
}

while getopts hndH opt
do
  case ${opt} in
    h ) usage
          exit 0;;
    n ) DRYRUNMODE=yes;;
    d ) DEBUGMODE=yes;;
    H ) ALLFILEMODE=;;
    ? ) usage
          exit 1;;
    * ) command="${command} '*${opt}'";;
  esac
done

echo "Temporary directory: ${MYTMPDIR}" >&2

mkdir ${MYTMPDIR}
trap "destruct" 0
trap "echo 'Caught signal.';exit 1;" INT TERM

if [ -z "${ALLFILEMODE}" ]; then
	
	STARTDATE=`date '+%s'`
	echo -n "inodelistを作成しています..." >&2
	find -L . -type f -print0 | xargs -0 ls -Ui1 > ${INODELISTF}
	ENDDATE=`date '+%s'`
	countline ${INODELISTF}
	calcdate ${STARTDATE} ${ENDDATE}

	STARTDATE=`date '+%s'`
	echo -n "inodelistをソートしています..." >&2
	#								  ↓スペースとタブ
	sort ${INODELISTF} | sed -e 's/^[ 	]*//g' > ${INODESORTF}
	ENDDATE=`date '+%s'`
	calcdate ${STARTDATE} ${ENDDATE}

	STARTDATE=`date '+%s'`
	echo -n "inodelistの重複を取り除いています..." >&2
	BUFIFS=$IFS
	IFS=

	PREVFILE=
	PREVINODE=
	NOWFILE=
	NOWINODE=

	exec 3< ${INODESORTF}
	exec 4> ${UNIQINODEF}

	while read FL 0<&3
	do
		PREVFILE=${NOWFILE}
		PREVINODE=${NOWINODE}
		NOWINODE=`echo ${FL} | cut -d' ' -f1`
		NOWFILE=`echo ${FL} | cut -d' ' -f2-`

		if [ "${NOWINODE}" != "${PREVINODE}" ]; then
			echo -n ${NOWFILE} 1>&4
			echo -ne '\0' 1>&4
		fi
	done
	exec 3<&-
	exec 4>&-

	IFS=$BUFIFS

	ENDDATE=`date '+%s'`
	calcdate ${STARTDATE} ${ENDDATE}
else
	echo -n "ファイルリストを作成しています..." >&2
	STARTDATE=`date '+%s'`
	find -L . -type f -print0 > ${UNIQINODEF}
	ENDDATE=`date '+%s'`
	calcdate ${STARTDATE} ${ENDDATE}
fi

STARTDATE=`date '+%s'`
echo -n "ハッシュを計算しています..." >&2
xargs -0 md5sum < ${UNIQINODEF} > ${HASHF}
ENDDATE=`date '+%s'`
countline ${HASHF}
calcdate ${STARTDATE} ${ENDDATE}

STARTDATE=`date '+%s'`
echo -n "ハッシュをソートしています..." >&2
sort ${HASHF} > ${HASHSORTF}
ENDDATE=`date '+%s'`
calcdate ${STARTDATE} ${ENDDATE}

if [ ! -z "${DRYRUNMODE}" ]; then
	echo "ハードリンクをスキップ" >&2
	exit 0
fi

echo "同一ファイルをハードリンクしています..." >&2


BUFIFS=$IFS
IFS=

PROCFCOUNT=0

PREVFILE=
PREVHASH=
NOWFILE=
NOWHASH=
exec 3< ${HASHSORTF}
while read FL 0<&3
do
	PREVFILE=${NOWFILE}
	PREVHASH=${NOWHASH}
	NOWHASH=`echo ${FL} | cut -d' ' -f1`
	NOWFILE=`echo ${FL} | cut -d' ' -f3-`
	if [ "${NOWHASH}" = "${PREVHASH}" ]; then
		diff "${NOWFILE}" "${PREVFILE}"
		ISDIFF=$?
		if [ ${ISDIFF} -eq 0 ]; then
			let PROCFCOUNT="${PROCFCOUNT} + 1"
			echo -ne "\r"
			ln -f ${PREVFILE} ${NOWFILE}
			printf "%5d files processed. " ${PROCFCOUNT} >&2
			if [ ! -z "${DEBUGMODE}" ]; then			
				echo "ln -f ${PREVFILE} ${NOWFILE}"
			fi
		elif [ ${ISDIFF} -eq 2 ]; then
			echo "different file: ${PREVFILE} ${NOWFILE}" >&2
		else
			echo "ERROR: diff returned ${ISDIFF}: diff '${PREVFILE}' '${NOWFILE}'" >&2
		fi
	fi	
done
exec 3<&-

IFS=$BUFIFS

ENDDATE=`date '+%s'`
calcdate ${STARTDATE} ${ENDDATE}



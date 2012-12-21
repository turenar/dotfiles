#!/bin/bash

MYNAME=`gettail $0`
MYTMPDIR="/tmp/${MYNAME}.$$"
INODELISTF="${MYTMPDIR}/inode.lst"
INODESORTF="${MYTMPDIR}/inode.sorted"
UNIQINODEF="${MYTMPDIR}/file.uniq"
HASHF="${MYTMPDIR}/md5sum"
HASHSORTF="${HASHF}.sorted"
DRYRUNMODE=yes
DEBUGMODE=
ALLFILEMODE=

STARTDATE=0
ENDDATE=0

function usage() {
  cat <<_EOM_ 1>&2
同一ファイルをハードリンクしてディスク領域を空かせるシェルプログラム。
ver.20110306

Usage:
  ${MYNAME} [options...]
Options:
  -h    このヘルプを表示する
  -n    ファイルの内容を変更しない (ハードリンクを作成しない) [DEFAULT=yes]
  -e    ファイルの内容を変更する (ハードリンクを作成する)
  -d    デバッグモード
  -a    すべてのファイルを処理対象にする。 (ハードリンクされたファイルを含む)
        ハードリンクの作成時にエラーが表示されることがあります。
  -H    inodeユニークなファイルを処理対象にする。 (ハードリンクされたファイルを含まない)
        [DEFAULT=yes]

Details:
  サポートしていないファイル:
     1. 空白が連続している (例 "a  b")
     2. 空白で終了している (例 "abc ")
    これらのファイルを処理しようとするとエラーが発生したり、
    目的のファイルではないファイルが処理される可能性があります。

ReleaseNote:
  2011-03-06:
    cutではなくreadを使うことによるループの処理速度の向上。
    作者の環境でループ内91+186sが3+5sになりました。全体で約40%の処理速度の向上。
  2011-01-14:
    sort -un を使うことによる処理速度の向上
  2011-01-07:
    コマンドラインオプションの追加
  2010-12-28:
    初リリース

Copyright (C) 2010-2011 Turenai Project
Licensed under CC-NC-BY.
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

while getopts hndHae opt
do
  case ${opt} in
    h ) usage
          exit 0;;
    n ) DRYRUNMODE=yes;;
	e ) DRYRUNMODE=;;
    d ) DEBUGMODE=yes;;
	a ) ALLFILEMODE=yes;;
    H ) ALLFILEMODE=;;
    ? ) usage
          exit 1;;
	* ) echo "BUG FOUND: ${opt} is not caught in case" >&2;;
  esac
done

if [ ! -z "${DRYRUNMODE}" ]; then
	echo !!Warning: DRY RUN MODE!! >&2
fi

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
	echo -n "inodelistをソートして重複を取り除いています..." >&2
	#								  ↓スペースとタブ
	sort -un ${INODELISTF} | sed -e 's/^[ 	]*//g' > ${INODESORTF}
	ENDDATE=`date '+%s'`
	calcdate ${STARTDATE} ${ENDDATE}

	STARTDATE=`date '+%s'`
	echo -n "ファイルリストを作成しています..." >&2
	BUFIFS=$IFS
	IFS=" "

	PREVFILE=
	PREVINODE=
	NOWFILE=
	NOWINODE=

	exec 3< ${INODESORTF}
	exec 4> ${UNIQINODEF}

	while read NOWINODE NOWFILE 0<&3
	do
		echo -n ${NOWFILE} 1>&4
		echo -ne '\0' 1>&4
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
IFS=" "

PROCFCOUNT=0

PREVFILE=
PREVHASH=
NOWFILE=
NOWHASH=
exec 3< ${HASHSORTF}
while read NOWHASH NOWFILE 0<&3
do
	if [ "${NOWHASH}" = "${PREVHASH}" ]; then
		diff "${NOWFILE}" "${PREVFILE}"
		ISDIFF=$?
		if [ ${ISDIFF} -eq 0 ]; then
			let PROCFCOUNT="${PROCFCOUNT} + 1"
			echo -ne "\r"
			ln -f "${PREVFILE}" "${NOWFILE}"
			printf "%5d files processed. " ${PROCFCOUNT}
			if [ ! -z "${DEBUGMODE}" ]; then			
				echo "ln -f '${PREVFILE}' '${NOWFILE}'"
			fi
		elif [ ${ISDIFF} -eq 2 ]; then
			echo "different file: ${PREVFILE} ${NOWFILE}" >&2
		else
			echo "ERROR: diff returned ${ISDIFF}: diff '${PREVFILE}' '${NOWFILE}'" >&2
		fi
	fi
	PREVFILE=${NOWFILE}
	PREVHASH=${NOWHASH}
done
exec 3<&-

IFS=$BUFIFS

ENDDATE=`date '+%s'`
calcdate ${STARTDATE} ${ENDDATE}



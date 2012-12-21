#!/bin/bash

MYNAME=`gettail $0`
MYTMPDIR="/tmp/${MYNAME}.$$"
INODELISTF="${MYTMPDIR}/inode.lst"
INODESORTF="${MYTMPDIR}/inode.sorted"
UNIQINODEF="${MYTMPDIR}/file.uniq"
HASHF="${MYTMPDIR}/md5sum"
HASHSORTF="${HASHF}.sorted"
CACHEFILE="${MYNAME}.cache"
TEMPFILE="${MYTMPDIR}/temp"
HashCombinedFile="${MYTMPDIR}/hash.combined"
DRYRUNMODE=yes
DEBUGMODE=
ALLFILEMODE=
CACHEMODE=
NOCACHEHASH=00000000000000000000000000000000
HASHMAKEFILE="${MYTMPDIR}/hashcheck"

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
  -c    キャッシュを利用する。変更されるようなファイルには使用しないでください。

Details:
  サポートしていないファイル:
     1. 空白が入っているファイル (キャッシュ利用時)
    これらのファイルを処理しようとするとエラーが発生したり、
    目的のファイルではないファイルが処理される可能性があります。

ReleaseNote:
  2011-04-17:
    ハッシュのキャッシュ機能を付けた。それに伴い
    
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
	echo -n "${linecount}files" >&2
}

while getopts hndHace opt
do
  case ${opt} in
    h ) usage
          exit 0;;
    n ) DRYRUNMODE=yes;;
	e ) DRYRUNMODE=;;
    d ) DEBUGMODE=yes;;
	a ) ALLFILEMODE=yes;;
    H ) ALLFILEMODE=;;
	c ) CACHEMODE=yes;;
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
	find -L . '!' -name "${CACHEFILE}" -type f -print0 | xargs -0 ls -Ui1 > ${INODELISTF}
	ENDDATE=`date '+%s'`
	countline ${INODELISTF}
	echo -n ": "
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

	NOWFILE=
	NOWINODE=

	exec 3< ${INODESORTF}
	exec 4> ${UNIQINODEF}

	while read NOWINODE NOWFILE 0<&3
	do
		echo ${NOWFILE} 1>&4
	done
	exec 3<&-
	exec 4>&-

	IFS=$BUFIFS

	ENDDATE=`date '+%s'`
	calcdate ${STARTDATE} ${ENDDATE}
else
	echo -n "ファイルリストを作成しています..." >&2
	STARTDATE=`date '+%s'`
	find -L . -type f > ${UNIQINODEF}
	ENDDATE=`date '+%s'`
	calcdate ${STARTDATE} ${ENDDATE}
fi

if [ '(' ! -z "${CACHEMODE}" ')' -a '(' -e "${CACHEFILE}" ')' ]; then
		echo -n "キャッシュを読み込んでいます..." >&2
		STARTDATE=`date '+%s'`
		sed -e "s/^/${NOCACHEHASH}  /" ${UNIQINODEF} | sed -e 's/  .\//  /' > ${TEMPFILE}
		cat ${CACHEFILE} ${TEMPFILE} | awk '{print $2,sprintf("%010g",NR),$0}' | sort \
			| cut -d " " -f3- > ${HashCombinedFile}
		# キャッシュに存在して実在しているファイルのハッシュ・ファイルリストの作成
		uniq -d -s34 ${HashCombinedFile} > ${HASHF}
		# キャッシュに存在しないか実在しないファイルのハッシュ・ファイルリストの作成
		uniq -u -s34 ${HashCombinedFile} > ${TEMPFILE}2
		
		BUFIFS=$IFS
		IFS=" "
		touch ${HASHMAKEFILE}
		exec 3< ${TEMPFILE}2
		while read uhash ufile 0<&3
		do
			if [ "${uhash}" = "${NOCACHEHASH}" ]; then
				# 新しく登録されたファイル
				echo ${ufile} >> ${HASHMAKEFILE}
			#else
				# 削除された（または動かされた）ファイルは何もしない
			fi
		done
		exec 3>&-
		ENDDATE=`date '+%s'`
		calcdate ${STARTDATE} ${ENDDATE}
else
	mv ${UNIQINODEF} ${HASHMAKEFILE}
fi



STARTDATE=`date '+%s'`
echo -n "ハッシュを計算しています..." >&2
xargs --no-run-if-empty -d '\n' md5sum < ${HASHMAKEFILE} >> ${HASHF}
ENDDATE=`date '+%s'`
wc -l ${HASHMAKEFILE} | cut -d ' ' -f1
echo -n "/" >&2
countline ${HASHF}
echo -n ": "
calcdate ${STARTDATE} ${ENDDATE}

STARTDATE=`date '+%s'`
echo -n "ハッシュをソートしています..." >&2
sort ${HASHF} > ${HASHSORTF}
ENDDATE=`date '+%s'`
calcdate ${STARTDATE} ${ENDDATE}

if [ ! -z "${DRYRUNMODE}" ]; then
	echo "ハードリンクをスキップ" >&2
else
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
			diff -q "${NOWFILE}" "${PREVFILE}"
			ISDIFF=$?
			if [ ${ISDIFF} -eq 0 ]; then
				let PROCFCOUNT="${PROCFCOUNT} + 1"
				echo -ne "\r"
				ln -f "${PREVFILE}" "${NOWFILE}"
				printf "%5d files processed. " ${PROCFCOUNT}
				if [ ! -z "${DEBUGMODE}" ]; then			
					echo "ln -f '${PREVFILE}' '${NOWFILE}'"
				fi
			elif [ ${ISDIFF} -eq 2 -o ${ISDIFF} -eq 1 ]; then
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
fi

if [ ! -z "${CACHEMODE}" ]; then
	cp ${HASHF} ${CACHEFILE}
fi

#!/bin/bash

MYNAME=`basename $0`
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
使用は自己責任でお願いします。
ver.6.4.1 (20121221)

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
     1. ファイル名に空白が連続して入っている
	 2. ファイル名に改行が入っているファイル名
    これらのファイルを処理しようとするとエラーが発生したり、
    目的のファイルではないファイルが処理される可能性があります。
  サポートが怪しいファイル:
     1. ファイル名に空白が入っている

  キャッシュ使用時の注意:
    変更されるようなファイルはキャッシュ機能を使用しないでください。
    予期せぬ動作をする可能性があります。

ReleaseNote:
  2012-12-21:
    ヘルプの更新
  2012-03-12:
    sortコマンドをLC_ALLで起動するように修正。
	キャッシュ操作の高速化24->4s
  2011-04-30:
    ファイルへの出力の仕方を修正。
  2011-04-20:
    諸々のバグ修正
  2011-04-17:
    ハッシュのキャッシュ機能を付けた。
  2011-03-06:
    cutではなくreadを使うことによるループの処理速度の向上。
  2011-01-14:
    sort -un を使うことによる処理速度の向上
  2011-01-07:
    コマンドラインオプションの追加
  2010-12-28:
    初リリース

Copyright (C) 2010-2012 Turenai Project
Licensed under MIT License.
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
	echo '!!Warning: DRY RUN MODE!!' >&2
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
	LC_ALL=C sort -un ${INODELISTF} | sed -e 's/^[ 	]*//g' > ${INODESORTF}
	ENDDATE=`date '+%s'`
	calcdate ${STARTDATE} ${ENDDATE}

	STARTDATE=`date '+%s'`
	echo -n "ファイルリストを作成しています..." >&2


	cut -d " " -f2- < ${INODESORTF} >${UNIQINODEF}

	ENDDATE=`date '+%s'`
	calcdate ${STARTDATE} ${ENDDATE}
else
	echo -n "ファイルリストを作成しています..." >&2
	STARTDATE=`date '+%s'`
	find -L . -type f -print > ${UNIQINODEF}
	ENDDATE=`date '+%s'`
	calcdate ${STARTDATE} ${ENDDATE}
fi

if [ '(' ! -z "${CACHEMODE}" ')' -a '(' -e "${CACHEFILE}" ')' ]; then
		echo -n "キャッシュを読み込んでいます..." >&2
		STARTDATE=`date '+%s'`
		sed -e "s/^/${NOCACHEHASH}  /" ${UNIQINODEF} > ${TEMPFILE}
		cat ${CACHEFILE} ${TEMPFILE} | sed -e 's/  \.\//  /' | awk '{print $2$3$4$5$6$7$8$9,sprintf("%010g",NR),$0}' | LC_ALL=C sort \
			| cut -d " " -f3-> ${HashCombinedFile}
		# キャッシュに存在して実在しているファイルのハッシュ・ファイルリストの作成
		uniq -d -s34 ${HashCombinedFile} > ${HASHF}
		# キャッシュに存在しないか実在しないファイルのハッシュ・ファイルリストの作成
		uniq -u -s34 ${HashCombinedFile} > ${TEMPFILE}2
		
		BUFIFS=$IFS
		IFS=" "
		touch ${HASHMAKEFILE}
		exec 3< ${TEMPFILE}2
		exec 4> ${HASHMAKEFILE}
		while read uhash ufile 0<&3
		do
			if [ "${uhash}" = "${NOCACHEHASH}" ]; then
				# 新しく登録されたファイル
				echo ${ufile} >&4
			#else
				# 削除された（または動かされた）ファイルは何もしない
			fi
		done
		exec 3<&-
		exec 4>&-
		ENDDATE=`date '+%s'`
		calcdate ${STARTDATE} ${ENDDATE}
		IFS=${BUFIFS}
else
	mv ${UNIQINODEF} ${HASHMAKEFILE}
fi



STARTDATE=`date '+%s'`
echo -n "ハッシュを計算しています..." >&2
xargs --no-run-if-empty -d '\n' md5sum < ${HASHMAKEFILE} >> ${HASHF}
ENDDATE=`date '+%s'`
echo -n $(wc -l ${HASHMAKEFILE} | cut -d ' ' -f1) >&2
echo -n "/" >&2
countline ${HASHF}
echo -n ": "
calcdate ${STARTDATE} ${ENDDATE}

STARTDATE=`date '+%s'`
echo -n "ハッシュをソートしています..." >&2
LC_ALL=C sort ${HASHF} > ${HASHSORTF}
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
			diff "${NOWFILE}" "${PREVFILE}" > /dev/null
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

#!/bin/bash
MYBINDIR="$(readlink -f "$(dirname "$0")")"
PREFIX=$(tinysb imagedir)
TARGETS='x86_64-w64-mingw32 i686-w64-mingw32'
BINUTILS_TARGETS=x86_64-w64-mingw32,i686-w64-mingw32
HOST_TRIPLET=x86_64-pc-linux-gnu
GCC_LANG=c,c++

main(){
	operation="${1:-upgrade}"
	case "$operation" in
		allclean)
			for i in binutils-gdb mingw-w64 gcc; do
				pushd $i >/dev/null 2>&1
				_log "Cleaning $(pwd)..."
				git reset --hard HEAD
				git clean -df
				popd >/dev/null 2>&1
			done
			echo "> done"
			;;
		distclean|clean)
			_pushd build
			for i in binutils* mingw-w64-crt* mingw-w64-headers* gcc*; do
				_pushd $i >/dev/null 2>&1
				_log "Cleaning $(pwd)..."
				make $operation
				_popd >/dev/null 2>&1
			done
			echo "> done"
			_popd
			;;
		upgrade)
			main update
			main build
			;;
		update)
			_pushd mingw-w64
			_cmd git pull
			_popd
			;;
		build)
			export FORCE_REFRESH=y
			test -d build || mkdir build
if false; then
			useignorefile=n
			ignorefile="${MYBINDIR}/archindep.sbignore"
			for target in ${TARGETS}; do
				_pushd build/binutils-${target}
				_cmd ../../binutils-gdb/configure \
					--target=${target} \
					--enable-targets=${target} \
					--with-sysroot=${PREFIX} \
					--libdir=$(getlibdir ${target}) \
					--prefix=${PREFIX} \
					--disable-multilib \
					--enable-lto \
					--enable-plugins
				_make
				_makei ${target}-gdb install
				_popd
				useignorefile=y
			done
		fi

			check_path ${PREFIX}/bin
			useignorefile=y
			ignorefile="${MYBINDIR}/mingw-header.sbignore"
			for target in ${TARGETS}; do
				_pushd build/mingw-w64-headers-${target}
				_cmd ../../mingw-w64/mingw-w64-headers/configure \
					--build=${target} \
					--host=${target} \
					--libdir=$(getlibdir ${target}) \
					--prefix=${PREFIX}/${target} \
					--enable-secure-api
				_make
				_makei ${target}-mingw-header install
				_popd
			done

			tinysb install mingw-env "$0" fix-env
			useignorefile=n
			ignorefile="${MYBINDIR}/archindep.sbignore"
			for target in ${TARGETS}; do
				if test ! -e "${PREFIX}/bin/${target}-gcc"; then
					_pushd build/gcc-${target}
					_cmd ../../gcc/configure \
						--target=${target} \
						--disable-multilib \
						--prefix=${PREFIX} \
						--with-sysroot=${PREFIX} \
						--libdir=$(getlibdir ${target}) \
						--enable-languages=${GCC_LANG}
					_make all-gcc
					_makei ${target}-gcc-stage1 install-gcc
					_popd
				fi
				useignorefile=y
			done

			useignorefile=n
			for target in ${TARGETS}; do
				_pushd build/mingw-w64-crt-${target}
				_cmd ../../mingw-w64/mingw-w64-crt/configure \
					--host=${target} \
					--with-sysroot=${PREFIX} \
					--prefix=${PREFIX}/${target} \
					--libdir=$(getlibdir ${target}) \
					--enable-secure-api \
					$(if64 ${target} --disable-lib32)
				_make
				_makei ${target}-mingw-crt install
				_popd
			done

			useignorefile=n
			for target in ${TARGETS}; do
				_pushd build/winpthreads-${target}
				_cmd ../../mingw-w64/mingw-w64-libraries/winpthreads/configure \
					--host=${target} \
					--with-sysroot=${PREFIX} \
					--prefix=${PREFIX}/${target}
				_make
				_makei ${target}-mingw-winpthreads install
				_popd
				useignorefile=y
			done

			useignorefile=n
			for target in ${TARGETS}; do
				_pushd build/gcc-${target}
				_cmd ../../gcc/configure --target=${target} \
					--enable-targets=${target} \
					--prefix=${PREFIX} \
					--with-sysroot=${PREFIX} \
					--with-build-sysroot=${PREFIX} \
					--libdir=$(getlibdir ${target}) \
					--enable-languages=${GCC_LANG} \
					--enable-threads=posix \
					--enable-libstdcxx-time=yes \
					--with-arch=native \
					--with-tune=native \
					--enable-lto \
					--with-plugin-ld \
					--disable-multilib \
					$(if32 ${target} --disable-sjlj-exceptions ) \
					$(if32 ${target} --with-dwarf2)
				_make
				tinysb disable gcc
				tinysb disable ${target}-gcc-stage1
				_makei ${target}-gcc install
				_popd
				useignorefile=y
			done

			_log "Completed jobs"
			echo -n ${message};;
		internal-prepenv)
			prepare_env
	esac
}

_log(){
	for i in $(seq 1 ${dirlevel}); do
		echo -n ">"
	done

	echo " $@..."
}

_cmd(){
	_log "Running $@"
	"$@" || exit 1
}

_make(){
	make "$@" ${MAKEOPTS} || exit 1
}
_makei(){
	local ignorefilearg=
	test x$useignorefile = xy && ignorefilearg="-E ${ignorefile}"
	~/bin/tinysb install ${ignorefilearg} "$1" make "$2" ${MAKEOPTS} || exit 1
}

_pushd(){
	_log "Entering $(readlink -f "$@")"
	dirlevel=$(( $dirlevel + 1 ))

	test -d "$@" || mkdir "$@" || exit 1
	pushd "$@" >/dev/null 2>&1
}

_popd(){
	dirlevel=$(( $dirlevel - 1 ))
	_log "Exiting $(pwd)"
	popd "$@" >/dev/null 2>&1
}

check_path(){
	if [[ $PATH == *:$1:* || $PATH == $1:* || $PATH == *:$1 ]]; then
		: #do nothing
	else
		_log "Adding $1 into temporary \$PATH"
		export PATH="$1:$PATH"
		add_msg "You must add $1 into \$PATH to use mingw."
		add_msg "Like this:"
		add_msg "	PATH=$1:\$PATH"
		add_msg ""
	fi
}

add_msg(){
	message="${message}$@${newline}"
}

getlibdir(){
	case "$1" in
		x86_64*)echo "${PREFIX}"/lib64;;
		i686*)	echo "${PREFIX}"/lib32;;
	esac
}

if32() {
	case "$1" in
		i686*)	echo "$2";;
	esac
}
if64() {
	case "$1" in
		x86_64*)echo "$2";;
	esac
}

newline='
'
dirlevel=1
message=

if [ "$1" = "fix-env" ]; then
	mkdir -p ${DESTDIR}/mingw
	cd ${DESTDIR}/mingw
	ln -s ../include include
	cd ..
	ln -s lib64 lib
	exit 0
fi

main "$@"

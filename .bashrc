source ${HOME}/.bashrc.d/loader ${HOME}/.bashrc.d

if [ -d "${HOME}/install" ]; then
	PATH="${HOME}/install/bin:${PATH}"
	LD_LIBRARY_PATH="${HOME}/install/lib"
fi

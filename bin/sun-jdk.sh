#!/bin/sh
export GENTOO_VM=sun-jdk-1.6
export JAVA_HOME=/opt/sun-jdk-1.6.0.37/
export JDK_HOME=${JAVA_HOME}
exec $@

## -*- docker-image-name: "clojureclibuild" -*-

# docker run -i -t clojureclibuild /bin/bash
# 

# Use an official ubuntu runtime as a parent image
FROM ubuntu:bionic

ENV PATH=$PATH:/root/.nimble/bin

# the base
RUN apt update && \
	apt -y install build-essential curl git perl mingw-w64 libzip-dev libz-dev wget zip unzip && \
	rm -rf /var/cache/apt/

# nim
RUN apt -y install xz-utils make
RUN CHOOSENIM_CHOOSE_VERSION="0.20.2" curl https://nim-lang.org/choosenim/init.sh -sSf | bash -s -- "-y"

# make ready to compile nsis
RUN apt -y install python2.7 python-pip scons
RUN mkdir /nsis && \
	curl -L https://netix.dl.sourceforge.net/project/nsis/NSIS%203/3.04/nsis-3.04.zip -o /nsis/nsis-3.04.zip && \
	curl -L https://netix.dl.sourceforge.net/project/nsis/NSIS%203/3.04/nsis-3.04-src.tar.bz2 -o /nsis/nsis-3.04-src.tar.bz2 && \
	unzip /nsis/nsis-3.04.zip -d /nsis && \
	tar -C /nsis -xvjf /nsis/nsis-3.04-src.tar.bz2 
# compile nsis
RUN cd /nsis/nsis-3.04-src && \
	scons SKIPSTUBS=all SKIPPLUGINS=all SKIPUTILS=all SKIPMISC=all NSIS_CONFIG_CONST_DATA=no PREFIX=/nsis/nsis-3.04 install-compiler

RUN chmod +x /nsis/nsis-3.04/bin/makensis && \
	ln -s /nsis/nsis-3.04/bin/makensis /usr/local/bin/makensis && \
	mkdir /nsis/nsis-3.04/share && \
	ln -s /nsis/nsis-3.04 /nsis/nsis-3.04/share/nsis

# our project
ADD . /clojure-cli-portable
WORKDIR /clojure-cli-portable
RUN nimble install zip -y

# RUN rm -rf out && mkdir out && mkdir /out
# VOLUME /out

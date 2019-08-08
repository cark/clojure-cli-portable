#!/bin/bash

function check {
    if [ $? -ne 0 ]
    then
	echo -e "\e[91m!!!!!!!!!!!!! ERROR : $1 !!!!!!!!!!!!!\e[0m"
	popd > /dev/null
	exit 1
    fi    
}

function p {
    echo -e "\e[93m**** $@ \e[0m"
}

script_dir=$(dirname $(readlink -f $0))
pushd . > /dev/null

dest_dir="/usr/local/clojure"
link_from="/usr/local/bin"

p "Installing to $dest_dir"
mkdir $dest_dir
cp -rf $script_dir/* $dest_dir

p "Creating links from $link_from to $dest_dir/clojure"
ln -fs $dest_dir/clojure $link_from/clojure
check 'Failed to create clojure link'
ln -fs $dest_dir/clj $link_from/clj
check 'Failed to create clj link'

popd > /dev/null
exit 0

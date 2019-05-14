#!/bin/sh

cd build 2>/dev/null || ( echo "Please run this command in the dev root" && exit )

rm -rf 'PDP-8:E Simulator.app'
cp -rp 'Release-32bit/PDP-8:E Simulator.app' 'PDP-8:E Simulator.app'

find 'PDP-8:E Simulator.app' -perm +111 -type f -exec lipo -create "Release-32bit/{}" "Release-64bit/{}" -output {} \;

cd ..

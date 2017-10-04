#!/bin/sh

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export DYLD_LIBRARY_PATH=../libusb/OSX:$DYLD_LIBRARY_PATH
export LD_LIBRARY_PATH=../libusb/OSX:$LD_LIBRARY_PATH
chmod a+x $dir/bulktest

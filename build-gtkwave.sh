#!/bin/bash

cd $HOME
cat > .gtkwaverc <<EOF
splash_disable on
initial_window_x 2560
EOF

sudo apt-get install tcl8.4-dev 
sudo apt-get install tk8.4-dev 
sudo apt-get install liblzma-dev

wget http://gtkwave.sourceforge.net/gtkwave-3.3.31.tar.gz
tar zxf gtkwave-3.3.31.tar.gz
cd gtkwave-3.3.31/
./configure --with-tcl=/usr/lib/tcl8.4 --with-tk=/usr/lib/tk8.4
make
sudo make install

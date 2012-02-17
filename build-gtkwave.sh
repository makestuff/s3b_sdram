#
# Copyright (C) 2012 Chris McClelland
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

#!/bin/bash
cd $HOME
cat > .gtkwaverc <<EOF
splash_disable on
initial_window_x 2560
color_back fafafa
color_0 000000
color_1 000000
color_baseline 00ff00
color_black 000000
color_brkred fafafa
color_dash 0000fe
color_dashfill 0000fd
color_dkblue 1010ff
color_dkgray 0000fb
color_gmstrd 0000fa
color_grid e0e0e0
color_grid2 0000f9
color_high 0000f8
color_low 0000f7
color_ltblue 0000f6
color_ltgray fafafa
color_mark 0000f5
color_mdgray fafafa
color_mid 808080
color_normal 0000f4
color_time 000000
color_timeb fafafa
color_trans 404040
color_u 0000f2
color_ufill 0000f1
color_umark ff0000
color_value 000000
color_vbox 000000
color_vtrans 404040
color_w 0000f0
color_wfill 0000ef
color_white e0e0e0
color_x 000000
color_xfill 0000ed
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

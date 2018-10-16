#!/usr/bin/env bash 
#SWARM is open-source software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#SWARM is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.

screen -S $2 -d -m
sleep .5
screen -S $2 -X logfile $4
sleep .5
screen -S $2 -X logfile flush 5
sleep .5
screen -S $2 -X log
sleep .5
screen -S $2 -X stuff $"export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$5\n"
sleep .5
screen -S $2 -X stuff $"cd\n"
sleep .5
screen -S $2 -X stuff $"cd $1\n"
sleep .5
screen -S $2 -X stuff $"$(< $3/config.sh)\n"
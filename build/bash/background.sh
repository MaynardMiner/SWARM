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

sudo screen -S background -d -m
sleep 1
sudo screen -S $1 -X stuff $"pwsh -command ./build/powershell/scripts/background.ps1 -WorkingDir $2\n"


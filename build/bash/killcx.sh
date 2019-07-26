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

while true; do
  for con in `netstat -anp 2>/dev/null | grep TIME_WAIT | grep $1 | awk '{print $5}'`; do
    sudo ./build/apps/killcx/killcx $con lo >/dev/null 2>&1
  done
    sudo netstat -anp 2>/dev/null | grep TIME_WAIT | grep $1 > /dev/null &&
    continue ||
    break
done

PKG_MANAGER=$( command -v yum || command -v apt-get || command -v pacman)
if [ $PKG_MANAGER == 'pacman' ]
 then
 $PKG_MANAGER -S libcurl3 -y
 else
 $PKG_MANAGER install libcurl3 -y
fi

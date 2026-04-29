#!/bin/bash
FILES="/etc/profile /etc/bashrc $HOME/.bash_profile $HOME/.bashrc $HOME/.bash_logout" 

for i in $FILES
do
	sed -i '/|->/d' $i
done

rm -f /etc/profile.d/test.sh >/dev/null

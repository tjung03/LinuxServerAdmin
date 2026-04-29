#!/bin/bash

FILES="/etc/profile /etc/bashrc $HOME/.bash_profile $HOME/.bashrc $HOME/.bash_logout" 

for i in $FILES
do
	sed -i "1i\echo \'|-> $i\'" $i
done

cat << EOF > /etc/profile.d/test.sh
#!/bin/bash
echo "|-> /etc/profile.d/test.sh"
EOF

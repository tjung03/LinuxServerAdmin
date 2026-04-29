#!/bin/bash

ps u | awk '{print $7}' | grep pts/ | sort -u > /root/bin/pts.list
cat /root/bin/pts.list | while read BTS
do
	cat /etc/MESS/CoffeeTime2.txt > /dev/$BTS
done

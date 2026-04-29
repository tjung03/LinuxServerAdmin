#!/bin/bash

echo "---- main.example.com ----"
ssh 192.168.10.10 $*
echo

echo "---- server1.example.com ----"
ssh 192.168.10.20 $*
echo

echo "---- server2.example.com ----"
ssh 192.168.10.30 $*
echo

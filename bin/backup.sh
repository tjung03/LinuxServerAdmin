#!/bin/bash

cd /home
tar cvzf /backup/home_$(date +%m%d_%H%M%S).tar.gz . > /backup/backup.log 2>&1


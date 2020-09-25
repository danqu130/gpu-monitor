#!/bin/bash

path=/tmp/gpuReadings
mkdir -p $path

if [ "$1" -eq "1" ]; then
    while true; do
    nvidia-smi --format=csv,noheader,nounits --query-gpu=index,uuid,name,memory.used,memory.total,utilization.gpu,utilization.memory,temperature.gpu,timestamp > $path/${HOST}_gpus.csv
    sleep 10
    done
fi

if [ "$1" -eq "2" ]; then
    while true; do
    nvidia-smi --format=csv,noheader,nounits --query-compute-apps=timestamp,gpu_uuid,used_gpu_memory,process_name,pid > $path/${HOST}_processes.csv
    sleep 10
    done
fi

if [ "$1" -eq "3" ]; then
    while true; do
        # echo "" > $path/${HOST}_status.csv
        df -l | grep "/dev/sda7" > $path/${HOST}_status.csv
        free -m | grep "Mem" >> $path/${HOST}_status.csv
        #top -b -n 1 | grep %Cpu >> $path/${HOST}_status.csv
        nproc --all >> $path/${HOST}_status.csv
        uptime >> $path/${HOST}_status.csv

        python /home/user/gpu-monitor/scripts/gpu-processes.py $path/${HOST}_processes.csv > $path/${HOST}_users.csv

        echo $(uptime | grep -o -P ': \K[0-9]*[,]?[0-9]*')\;$(nproc) > $path/${HOST}_cpus.csv
        # tail -n 20 $path/gpus.csv > $path/${HOST}_gpus.csv
        # tail -n 40 $path/processes.csv > $path/${HOST}_processes.csv
        # cp $path/${HOST}_* /var/www/html/gpu/data
        # echo $2\;$3\;$4
        timeout 10 scp -P $4 $path/${HOST}_* $2@$3:/var/www/html/gpu/data
        sleep 10
    done
fi

if [ "$1" -eq "4" ]; then
    while true; do
        du -sh /home/* > /tmp/local-usage.txt 2>/dev/null
        cp /tmp/local-usage.txt $path/${HOST}_local.txt
        sleep 120
    done
fi
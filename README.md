# GPU Monitor

This is a tool intended to monitor the GPU usage on the various GPU-servers at the NPU CVR Lab, Northwestern Polytechnical University, Xi'an Shaanxi, 710072, P.R.China. This project is orginally created by [LIP6 Lab, UPMC, Paris](https://github.com/ThomasRobertFr/gpu-monitor), thanks for the open source. This code has been written with the "quickest and dirtiest" principle in mind, it is absolutely awful, please do not read it :persevere:

The principle is as follows. A bunch of Bash / Python scripts runs regularly `nvidia-smi` and `ps` to extract data and sends them to my `public_html` space. Each time someone wants to see the status of the GPUs, the page `index.php` reads the latest data files for each server and displays those.

## How to setup

### Environment

#### python (on each server)

Need `dateutil` package in `gpu-processes.py`, must install to the *system default* python environment.

```shell
sudo apt install python-dateutil
```

#### web server (only on master server)

https://www.jianshu.com/p/9d836edf048c

- First install nginx, 
```shell
sudo apt install -y nginx
```

- Then install php,
```shell
sudo apt install -y php7.0 php7.0-mysql php7.0-gd php7.0-xml php7.0-curl php7.0-zip
```

- Config nginx and php, 
``` shell
cd /etc/nginx/
cp sites-available/default sites-available/default.bak
vim sites-enabled/default
```

``` 
location ~ \.php$ {                                           # uncomment this line
                include snippets/fastcgi-php.conf;            # uncomment this line
        #       # With php7.0-cgi alone:
        #       fastcgi_pass 127.0.0.1:9000;
        #       # With php7.0-fpm:
                fastcgi_pass unix:/run/php/php7.0-fpm.sock;   # uncomment this line
}                                                             # uncomment this line
```

check php config
``` shell
vim /etc/php/7.0/fpm/pool.d/www.conf
```

``` shell
listen = /run/php/php7.0-fpm.sock    # uncomment this line
# listen = 127.0.0.1:9000   # comment this line
```


then restart nginx and test it

```shell
/etc/init.d/nginx restart
```

### Change localtime and update time

change localtime

``` shell
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
data -R
```

update time
``` shell
sudo apt install ntpdate
ntpdate cn.pool.ntp.org
date -R
```

### Monitoring setup

Put the files that are in the `scripts` folder on the machines you want to monitor. The scripts are as follows:

* `gpu-run.sh <task_id>` loops on one of the three tasks (`task_id` being `1`, `2` or `3`). Task 1 extracts GPU usage stats each 20s, task 2 extracts GPU processes each 20s, task 3 extracts ps info tha corresponds to GPU processes each 10s and copies all the monitoring files to the `public_html` space. This scripts uses the `HOST` env variable.
* `gpu-processes.py` is what's ran by task 3
* `gpu-check.sh <hostname>` checks if the 3 tasks are running, if not it will launch them in the background. Also `gpu-check.sh kill` will stop the tasks if running.

Just edit `gpu-run.sh` to change the `scp` command that is in it so that it sends file to the right location (i.e. the `data` folder of the _www_ location of the web monitor). If you do need scp, make sure you have an SSH keys setup so that we can do passwordless copy.

Ideally, on the machines you want to monitor, use the following *cron* jobs:

```shell
crontab -e
sudo sevice cron restart
```

```
# Edit full-caps infos below
# Check if monitoring running each 5 min
*/5 * * * * /home/user/gpu-monitor/scripts/gpu-check.sh [client_name] [user] [ip] [port] > /dev/null 2>&1
# Kill and restart the monitoring each 2 hours to cleanup the ouptput files of the monitors (optional)
# 0 */2 * * * /SCRIPT-LOCATION/gpu-check.sh kill > /dev/null 2>&1; /SCRIPT-LOCATION/gpu-check.sh HOSTNAME HTTP_SERVER > /dev/null 2>&1
```

### Login without passwd

copy ssh key from clients to server host
```
ssh-keygen -t rsa
ssh-copy-id -i ~/.ssh/id_rsa.pub -p [port] [username]@[server_ip]
```

then restart moniter
```
/home/user/gpu-monitor/scripts/gpu-check.sh kill
/home/user/gpu-monitor/scripts/gpu-check.sh [client_name] [user] [ip] [port]
```


### Web interface setup

To setup the web interface, you just need to put the files of the repo (except `scripts` folder) on the www space of a web server that supports PHP.

Simply edit the `index.php` file to each the `$HOSTS` variable and optionnaly the `$SHORT_GPU_NAMES` variable.

`$HOSTS` associates the hostnames with some viewable names for these hosts. The keys are the ones entered as `HOSTNAME` in the crontab above and the `<hostname>` parameter of `gpu-check`.

`$SHORT_GPU_NAMES` allows you to rewrite GPU names if you want. It associates the names given by `nvidia-smi` to the names you want to be displayed.

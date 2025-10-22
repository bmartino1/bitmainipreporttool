Janky but functioal Wine VNC add zip.exe file and run app.

Docker run --name='Bitman-IP-Report-Tool' --net='bridge' --pids-limit 2048 -e TZ="America/Chicago" -e HOST_CONTAINERNAME="Bitman-IP-Report-Tool" -e 'USER_ID'='0' -e 'GROUP_ID'='0' -l net.unraid.docker.managed=dockerman -l net.unraid.docker.webui='http://[IP]:[PORT:5800]' -l net.unraid.docker.icon='https://cdn-icons-png.freepik.com/256/12429/12429352.png' -p '5800:5800/tcp' -v '/mnt/user/appdata/ipreport/zip/':'/zip':'rw' --cap-add=NET_ADMIN 'bmmbmm01/bitmainipreporttool:latest'

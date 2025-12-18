

docker system prune -a --volumes
# Or more specific commands:
docker image prune -a
docker container prune
docker volume prune

$docker_data_vhd_path = "C:\Users\sohfer\AppData\Local\Docker\wsl\disk\docker_data.vhdx"

# quit docker
Stop-Service docker

#stop wsl
wsl --shutdown

Optimize-VHD -Path $docker_data_vhd_path -Mode Full

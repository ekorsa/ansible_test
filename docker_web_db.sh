#/bin/bash
#
# Запуск веб-сервера
docker run -d --name web_server \
  -p 8080:80 -p 2221:22 \
  --privileged \
  --cgroupns=host \
  --tmpfs /run --tmpfs /run/lock \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  trfore/docker-ubuntu2404-systemd:latest

# Запуск базы данных
docker run -d --name db_server \
  -p 2222:22 \
  --privileged \
  --cgroupns=host \
  --tmpfs /run --tmpfs /run/lock \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  trfore/docker-ubuntu2404-systemd:latest

# Устанавливаем и включаем SSH на веб-сервере
docker exec -it web_server bash -c "apt update && apt install openssh-server -y && systemctl start ssh && echo 'root:root' | chpasswd"

# Устанавливаем и включаем SSH на сервере базы данных
docker exec -it db_server bash -c "apt update && apt install openssh-server -y && systemctl start ssh && echo 'root:root' | chpasswd"


# Включаем SSH и задаем пароль root для веб-сервера
docker exec -it web_server bash -c "systemctl start ssh && echo 'root:root' | chpasswd"

# Включаем SSH и задаем пароль root для сервера базы данных
docker exec -it db_server bash -c "systemctl start ssh && echo 'root:root' | chpasswd"

# Разрешаем вход root по паролю для веб-сервера и перезапускаем SSH
docker exec -it web_server bash -c "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && systemctl restart ssh"

# Разрешаем вход root по паролю для сервера базы данных и перезапускаем SSH
docker exec -it db_server bash -c "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && systemctl restart ssh"


docker exec -it web_server bash -c "echo 'nameserver 8.8.8.8' > /etc/resolv.conf"
docker exec -it web_server bash -c "echo 'Acquire::ForceIPv4 \"true\";' > /etc/apt/apt.conf.d/99force-ipv4"


docker exec -it db_server bash -c "echo 'nameserver 8.8.8.8' > /etc/resolv.conf"
docker exec -it db_server bash -c "echo 'Acquire::ForceIPv4 \"true\";' > /etc/apt/apt.conf.d/99force-ipv4"


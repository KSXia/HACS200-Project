#!/bin/bash

if [[ $# -ne 0 ]]
then
  echo "[Usage]: ./create.bash"
  exit 1
fi

lxc image delete base-img
lxc info base-img &>/dev/null && (lxc stop base-img; lxc delete base-img)

echo "[INFO] Launching Container "
lxc launch ubuntu:20.04 base-img > /dev/null

echo "[INFO] Installing sshd"
sleep 3 # Trust me this is extremely important the container needs time to update it's hostname before using sudo commands
lxc exec base-img -- sudo apt-get install openssh-server >/dev/null
lxc exec base-img -- sudo rm -rf /etc/ssh/sshd_config.d
lxc exec base-img -- bash -c "sudo echo PasswordAuthentication yes > /etc/ssh/sshd_config"
lxc exec base-img -- bash -c "sudo echo PubkeyAuthentication no >> /etc/ssh/sshd_config"
lxc exec base-img -- bash -c "sudo echo PermitRootLogin yes >> /etc/ssh/sshd_config"
lxc exec base-img -- sudo systemctl stop ssh >/dev/null

# Stop cloud-init from resetting the hostname to the container name on boot
# (creation.bash sets the real hostname per container)
lxc exec base-img -- bash -c "echo 'preserve_hostname: true' > /etc/cloud/cloud.cfg.d/99-preserve-hostname.cfg"

echo "[INFO] Adding in treatments"
lxc file push -r ../container-files/ssl-cont/etc/ base-img/
lxc file push -r ../container-files/ssh-cont/.ssh base-img/
lxc file push -r ../container-files/api-cont/.env base-img/
lxc file push -r ../container-files/control-cont/AI-Powered-Tutor base-img/

# A nested .git can't be committed to this repo, so build the fake git history in the image
echo "[INFO] Initializing fake git repo"
GIT="git -c user.name='Alex Morgan' -c user.email='alex.morgan@example.com'"
lxc exec base-img -- chown -R root:root /AI-Powered-Tutor
lxc exec base-img -- bash -c "cd /AI-Powered-Tutor && git init -q   && git add README.md .gitignore .env.example requirements.txt Makefile Dockerfile config.py   && GIT_AUTHOR_DATE='2025-09-02T14:12:09' GIT_COMMITTER_DATE='2025-09-02T14:12:09' $GIT commit -q -m 'Initial project skeleton'   && git add tutor app.py wsgi.py migrations   && GIT_AUTHOR_DATE='2025-09-09T10:41:30' GIT_COMMITTER_DATE='2025-09-09T10:41:30' $GIT commit -q -m 'Add ask and practice endpoints'   && git add -A   && GIT_AUTHOR_DATE='2025-09-16T16:05:52' GIT_COMMITTER_DATE='2025-09-16T16:05:52' $GIT commit -q -m 'Add tests and API docs'"

echo "[INFO] Completed base image setup"

echo "[INFO] Stopping container"
lxc stop base-img

echo "[INFO] Publishing image"
lxc publish base-img --alias base-img
lxc delete base-img

echo "[INFO] Image creation complete!"



#!/bin/bash

CONTAINERS=()


if [[ $# -gt 0 ]]
then
	CONTAINERS=$@
fi

if [[ $# -eq 0 ]]
then
	CONTAINERS=("cont-cont" "ssh-cont" "ssl-cont" "api-cont")
fi

for container in ${CONTAINERS[@]};
do
	if [[ $container == "cont-cont" || $container == "cont" || $container -eq 0 || $container == "control" ]]
	then
		image_name="cont-cont"
		lxc image delete ssh-cont

		./create-base-img.sh $image_name
		
		echo "[INFO] Stopping container"
		lxc stop $image_name

		echo "[INFO] Publishing image"
		lxc publish $image_name --alias $image_name

		echo "[INFO] Completed image creation for \"$image_name\""
	elif [[ $container == "ssh-cont" || $container == "ssh" || $container -eq 1 ]]
        then
                image_name="ssh-cont"
		lxc image delete ssh-cont

                ./create-base-img.sh $image_name
		./create-ssh-img.sh $image_name

                echo "[INFO] Stopping container"
                lxc stop $image_name

                echo "[INFO] Publishing image"
                lxc publish $image_name --alias $image_name

                echo "[INFO] Completed image creation for \"$image_name\""
        elif [[ $container == "ssl-cont" || $container == "ssl" || $container -eq 2 ]]
        then
                image_name="ssl-cont"
		lxc image delete ssh-cont
                
		./create-base-img.sh $image_name
                ./create-ssl-img.sh $image_name

                echo "[INFO] Stopping container"
                lxc stop $image_name

                echo "[INFO] Publishing image"
                lxc publish $image_name --alias $image_name

                echo "[INFO] Completed image creation for \"$image_name\""
        elif [[ $container == "api-cont" || $container == "api" || $container -eq 3 ]]
        then
                image_name="ssh-cont"
		lxc image delete ssh-cont

                ./create-base-img.sh $image_name
                ./create-ssh-img.sh $image_name

                echo "[INFO] Stopping container"
                lxc stop $image_name

                echo "[INFO] Publishing image"
                lxc publish $image_name --alias $image_name

                echo "[INFO] Completed image creation for \"$image_name\""
	else
		echo -e "\e[31m[ERROR] Couldn't identify what image correlates to the input \"$container\" \e[0m"
	fi
done

lxc image list

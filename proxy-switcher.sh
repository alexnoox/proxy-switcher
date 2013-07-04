#!/bin/bash

sudo -v -p "Please enter you admin password: "

function setup {
	echo -e "\e[32mSet-up the proxy:\e[0m ${proxy}"
	echo "export http_proxy=\"http://${proxy}\"" | sudo tee /etc/bash.bashrc -a
	echo "export https_proxy=\"http://${proxy}\"" | sudo tee /etc/bash.bashrc -a
	echo "Acquire::http::Proxy \"http://${proxy}\";" | sudo tee /etc/apt/apt.conf.d/proxy -a
	sudo sed -i "s_Exec=/opt/google/chrome/google-chrome %U_Exec=/opt/google/chrome/google-chrome %U --proxy-server=${proxy}_" /usr/share/applications/google-chrome.desktop
	export http_proxy="http://${proxy}"
	export https_proxy="http://${proxy}"
}

function remove {
	echo -e "\e[32mRemove the proxy\e[0m"
	sudo sed -i '/export http_proxy=/d' /etc/bash.bashrc
	sudo sed -i '/export https_proxy=/d' /etc/bash.bashrc
	if [[ -f /etc/apt/apt.conf.d/proxy ]]
	then
		sudo rm /etc/apt/apt.conf.d/proxy
	fi
	sudo sed -i "s_Exec=/opt/google/chrome/google-chrome %U --proxy-server=.*_Exec=/opt/google/chrome/google-chrome %U_" /usr/share/applications/google-chrome.desktop
	unset http_proxy
	unset https_proxy
}

if [[ $1 != "" ]]
then
	proxy=$1
	remove
	setup
else
	remove
fi

#!/bin/bash

sudo -v -p "Please enter you admin password: "

function setup {
	echo -e "\e[32mSet-up the proxy:\e[0m ${proxy}"
	echo "export http_proxy=\"http://${proxy}\"" | sudo tee /etc/bash.bashrc -a
	echo "export https_proxy=\"http://${proxy}\"" | sudo tee /etc/bash.bashrc -a
	echo "Acquire::http::Proxy \"http://${proxy}\";" | sudo tee /etc/apt/apt.conf.d/proxy.conf -a
	if [[ -f /usr/share/applications/google-chrome.desktop ]]
	then
		sudo sed -i "s_Exec=/opt/google/chrome/google-chrome %U_Exec=/opt/google/chrome/google-chrome %U --proxy-server=${proxy}_" /usr/share/applications/google-chrome.desktop
	fi
	export http_proxy="http://${proxy}"
	export https_proxy="http://${proxy}"

	if  [ -x "$(command -v git)" ]; then
		git config --global http.proxy "http://${proxy}"
		git config --global https.proxy "http://${proxy}"
	fi

	if  [ -x "$(command -v npm)" ]; then
		npm config set proxy "http://${proxy}"
		npm config set https-proxy "http://${proxy}"  
	fi

	if  [ -x "$(command -v yarn)" ]; then
		yarn config set proxy "http://${proxy}"
		yarn config set https-proxy "http://${proxy}"  
	fi

}

function remove {
	echo -e "\e[32mRemove the proxy\e[0m"
	sudo sed -i '/export http_proxy=/d' /etc/bash.bashrc
	sudo sed -i '/export https_proxy=/d' /etc/bash.bashrc
	if [[ -f /etc/apt/apt.conf.d/proxy.conf ]]
	then
		sudo rm /etc/apt/apt.conf.d/proxy.conf
	fi
	if [[ -f /usr/share/applications/google-chrome.desktop ]]
	then
		sudo sed -i "s_Exec=/opt/google/chrome/google-chrome %U --proxy-server=.*_Exec=/opt/google/chrome/google-chrome %U_" /usr/share/applications/google-chrome.desktop
	fi

	unset http_proxy
	unset https_proxy

	if  [ -x "$(command -v git)" ]; then
		git config --global http.proxy ""
		git config --global https.proxy ""
	fi

	if  [ -x "$(command -v npm)" ]; then
		npm config set proxy ""
		npm config set https-proxy ""  
	fi

	if  [ -x "$(command -v yarn)" ]; then
		yarn config set proxy ""
		yarn config set https-proxy ""  
	fi

}

if [[ $1 != "" ]]
then
	proxy=$1
	remove
	setup
else
	remove
fi
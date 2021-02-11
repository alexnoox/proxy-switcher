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
		npm config set proxy "http://${proxy}" --global 
		npm config set https-proxy "http://${proxy}"  --global 
	fi

	if  [ -x "$(command -v yarn)" ]; then
		yarn config set proxy "http://${proxy}"
		yarn config set https-proxy "http://${proxy}"  
	fi
	if [ -x "$(command -v docker)" ]; then
		echo "[Service]\nEnvironment=\"HTTP_PROXY=${proxy}/\"\nEnvironment=\"HTTPS_PROXY=${proxy}/\"\nEnvironment=\"NO_PROXY=localhost,127.0.0.1,localaddress,.localdomain.com\"" | sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf
		if [ -x $(command -v jq) ]; then
			cat ~/.docker/config.json | jq --arg newProxy $proxy --arg noProxy "localhost,127.0.0.1,localaddress,.localdomain.com" '. + {proxies:{ default:{ httpProxy: $newProxy, httpsProxy: $newProxy, noProxy: $noProxy }}}' | tee ~/.docker/config.json
		else
			echo "You should install jq for handling json files. Run sudo apt install -y jq"
		fi
		sudo systemctl daemon-reload
		sudo service docker restart
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
		npm config rm proxy
		npm config rm https-proxy
		npm config --global rm proxy
		npm config --global rm https-proxy
	fi

	if  [ -x "$(command -v yarn)" ]; then
		yarn config set proxy ""
		yarn config set https-proxy ""  
	fi

	if [ -x "$(command -v docker)" ];then
		if [ -f /etc/systemd/system/docker.service.d/http-proxy.conf ]; then
		 sudo rm /etc/systemd/system/docker.service.d/http-proxy.conf
		 sudo systemctl daemon-reload
		 sudo service docker restart
		fi
		if [ -x "$(command -v jq)" ]; then
			if [ -f ~/.docker/config.json ]; then
				cat ~/.docker/config.json | jq 'del(.proxies)' | tee ~/.docker/config.json
			fi
		else
			echo "You should install jq for handling json files. Run sudo apt install -y jq"
		fi
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
#!/bin/bash

# Configurando variaveis do shell


#DATA=`date +'%d-%m-%Y-%H-%M'`
#VERSAO="v0.1"
#LICENSE="MIT Lincense"
#HOSTNAME=`hostname`
#INTERFACE=`ip route show | awk '/default via/ {print $5}'`
#INTERFACE=`iw dev | awk '/Interface/' {print $2}'`
#INTERFACEMON=mon0
#GATEWAY=`ip route show | awk '/default via/ {print $3}'`
#IPINTERNO=`ip route show | awk '/src/ {print $9}'`
#IPEXTERNO=`curl -s ipinfo.io/ip`
#MACATUAL=`ip address | awk '/ether/ {print $2}'`
#MACFALSO=
DIR=`pwd`
#ARQTMP=
ARQ=teste



#MENU

# funçoes a serem criadas
#public_ip
#verificar_usuario

function verificar_dependencias(){
	if ! hash yad 2> /dev/null; then
		echo "[ FALHA ] yad dialog nao instalado!"
		exit 1
	fi

	if ! hash aircrack-ng 2>/dev/null; then
		echo "[ FALHA ] aircrack-ng nao instalado!"
		exit 1
	fi
	
	if ! hash xfce4-terminal 2> /dev/null; then
		echo "[ FALHA ] xfce4-terminal nao instalado!"
		exit 1	
	fi

	if ! hash reaver 2> /dev/null; then
		echo "[ FALHA ] reaver nao instalado!"
		exit 1
	fi	
}

function iniciar_mon() {
# Adiciona a interface de monitoramento wlan0mon. Caso contrario, emite mensagem de erro
iw dev wlan0 interface add wlan0mon type monitor &> /dev/null && ifconfig wlan0mon up &> /dev/null && \
echo -e "[ ok ] modo monitoramento ativado!" || echo -e "[ falha ] erro em iniciar modo monitor."

}

function matar_processos_que_atrapalham_suite(){
# há alguns processos que atrapalham a suite aircrack
# exemplo: NetworkManager, wpa_supplicant, dhclient, avahi-daemon...
# Para verificar se existem processos que atrapalham a suite aircrack:
# 	airmon-ng check

# Matar processos que atrapalham a suite aircrack-ng
airmon-ng check kill &> /dev/null

}

function conf_interface(){
ifconfig wlan0 &> /dev/null
if [ $? != 0 ]; then
	ifconfig wlan0 up &> /dev/null
fi

}

function escanear_todas_redes(){
# Escanear todas redes encontradas pelo adaptador de rede sem fio. Caso contrario, emite um erro.
(xterm -geometry 85x25 -title "Escaneando todas as redes" -e "airodump-ng wlan0mon" &) || \
echo -e "[ FALHA ] Ocorreram erros!"

}


function setar_parametros(){
	PARAMETROS=$(yad --title "$TITLE" \
	--form \
	--field "BSSID" "" \
	--field "ESSID" "" \
	--field "Channel" "" \
	--field "Interface Mon" "wlan0mon" \
	#--field "Salvar em" "$DATE.cap" \
	#--field "[ Wordlist ]":BTN "yad --file --maximized" \
	#--field "[ Salvar na pasta ]":BTN "yad --title $TITLE --maximized --file --directory" \
	--button ok \
	--button cancel \
	--undecorated \
	--center & )

	BSSID=$(echo "$PARAMETROS" | cut -d '|' -f 1)
	ESSID=$(echo "$PARAMETROS" | cut -d '|' -f 2)
	CHANNEL=$(echo "$PARAMETROS" | cut -d '|' -f 3)
	INTERFACE_MON=$(echo "$PARAMETROS" | cut -d '|' -f 4)
	#DIR=$(echo "$PARAMETROS" | cut -d '|' -f 5)
	#ARQ=$(echo "$PARAMETROS" | cut -d '|' -f 5)

	escanear_uma_rede
}

function escanear_uma_rede() {
# Verifica se os 4 parametros obrigatorios para uso da função estão setados.
if [ -z $BSSID  ] || [ -z $ESSID ] || [ -z $CHANNEL ] || [ -z INTERFACE_MON ] ; then
	echo "[ FALHA ] Falta parametros para o escaneamento da rede!"
	exit 1
fi

(xterm -geometry 85x25 -title "Escaneando rede especifica" -e "airodump-ng \
--bssid $BSSID \
--essid $ESSID \
--channel $CHANNEL \
--write $DIR/$ARQ $INTERFACE_MON" &) || \
echo -e "[ FALHA ] Ocorreram erros"

}

function deauth_todos() {
# Desautentica todas as STA do AP
(aireplay-ng --interactive 1000 -c $CLIENTE wlan0mon) || \
echo "[ FALHA ] Ocorreram erros em fazer o deauth do cliente: $CLIENTE"

}

#function deauth_mdk3() {
#xterm $HOLD $BOTTOMRIGHT -bg "#000000" -fg "#FF0009" -title "Deauthenticating via mdk3 all clients on $Host_SSID" -e mdk3 $WIFI_MONITOR d -b $DUMP_PATH/mdk3.txt -c $Host_CHAN & 
#|| { echo "[ FALHA ]"; }
#}

#function deauth_alvo_especifico() {
#xterm $HOLD $BOTTOMRIGHT -bg "#000000" -fg "#FF0009" -title "Deauthenticating client $Client_MAC" -e aireplay-ng -0 $DEAUTHTIME -a $Host_MAC -c $Client_MAC --ignore-negative-one $WIFI & 
#|| { echo "[ FALHA ]"; }
#}


#function injetar(){
#(aireplay-ng --interactive 1000 -c $CLIENTE $INTERFACE_MON) || echo "[ FALHA ]"
#}

#function brute_force_psk() {
#(aircrack-ng -w $WORDLIST $OUTPUT/$ARQ) || echo "[ FALHA ]"
#}

function matar_todos_processos() {

iw dev wlan0mon del
pkill xterm
pkill airodump-ng
pkill aireplay-ng
pkill airmon-ng 
service networking restart

}

function alterar_mac() {
	ifdown $INTERFACE &> /dev/null || echo "[ ok ] ifdown";
	macchanger -r $INTERFACE &> /dev/null
	ifup $INTERFACE &> /dev/null || echo "[ ok ] ifup"

	MACFALSO=`ip address | awk '/ether/ {print $2}'`

return 0

}
#function parametros_obrigatorios() {
#}


#function config() {
#echo
#}

#function ip_publico() {
# Obtem oo endereço ip publico
#IPPUBLICO=`curl -s ipinfo.io/ip`
# precisa testar se o curl executou com sucesso
#}


#function infoap() {
#Host_MAC_info1=`echo $Host_MAC | awk 'BEGIN { FS = ":" } ; { print $1":"$2":"$3}' |$
#Host_MAC_MODEL=`macchanger -l | grep $Host_MAC_info1 | cut -d " " -f 5-`
#echo
#}

verificar_dependencias
matar_processos_que_atrapalham_suite
conf_interface
iniciar_mon
escanear_todas_redes
setar_parametros
#matar_todos_processos

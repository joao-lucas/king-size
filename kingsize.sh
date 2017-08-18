#!/bin/bash

# Configurando variaveis do shell


DATA=`date +'%d-%m-%Y-%H-%M'`
VERSAO="v0.1"
LICENSE="MIT Lincense"
HOSTNAME=`hostname`
#INTERFACE=`ip route show | awk '/default via/ {print $5}'`
INTERFACE=`iw dev | awk '/Interface/' {print $2}'`
INTERFACEMON=mon0
GATEWAY=`ip route show | awk '/default via/ {print $3}'`
IPINTERNO=`ip route show | awk '/src/ {print $9}'`
IPEXTERNO=`curl -s ipinfo.io/ip`
MACATUAL=`ip address | awk '/ether/ {print $2}'`
MACFALSO=
DIR=`pwd`
ARQTMP=
ARQ=



#MENU

# funçoes a serem criadas
# change mac
#set_interface
#install_depends
#check_depends
#public_ip
#verificar_usuario


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

function matar_processos_que_atrapalham_suite(){
# há alguns processos que atrapalham a suite aircrack
# exemplo: NetworkManager, wpa_supplicant, dhclient, avahi-daemon...
# Para verificar se existem processos que atrapalham a suite aircrack:
#	 airmon-ng check
# Matar todos processos
airmon-ng check kill

}


function iniciar_monitoramento() {
airmon-ng start $INTERFACE &>/dev/null && echo -e "[ OK ] Modo monitoramento ativado!" || { echo -e "Error starting monitor mode."; }
iw dev $INTERFACE interface add mon0 type monitor
ifconfig mon0 up
}

#function escanear_todas_redes(){
#(xfce-terminal -e "airodump $INTERFACE_MON" & ) || { echo -e "[ FALHA ] Ocorreram erros "; }
#}

#function escanear_uma_rede() {
#i f [ $# -lt 4 ]; then
#(xfce4-terminal -e "airodump-ng --bssid $BSSID --essid $ESSID --channel $CHANNEL --write $OUTPUT/$ARQ $INTERFACE_MON" & ) || { echo -e "[ FALHA ]"; }
#else
#	echo "[ FALHA ]"
#fi
#}

#function deauth_todos() {
#(aireplay-ng --interactive 1000 -c $CLIENTE $INTERFACE_MON) || { echo "[ FALHA ]"; }
#}

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

#function matar_todos_processos() {
#killall aireplay-ng &> /dev/null
#killall dhcpd &> /dev/null
#killall xterm &> /dev/null
#}

function alterar_mac() {
	ifdown $INTERFACE &> /dev/null || echo "[ ok ] ifdown";
	macchanger -r $INTERFACE &> /dev/null
	ifup $INTERFACE &> /dev/null || echo "[ ok ] ifup"

	MACFALSO=`ip address | awk '/ether/ {print $2}'`

return 0

}

echo "HOSTNAME: " $HOSTNAME
echo "GATEWAY: " $GATEWAY
echo "IP INTERNO: " $IPINTERNO
echo "IP EXTERNO: " $IPEXTERNO
echo "INTERFACE:" $INTERFACE
echo "MAC PADRAO:" $MACATUAL
alterar_mac
echo "MAC FALSO: " $MACFALSO

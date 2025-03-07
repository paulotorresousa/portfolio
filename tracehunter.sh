#!/bin/bash

echo -e  "\033[1;34m TraceHunter-Forensic Collector \033[0m"

#Verficar o script esta rodando como root
if [[ $EUID -ne 0 ]]; then
        echo -e "\033[1;31m Este script só roda como root. \033[0m "
        exit 1
fi

# Criando  dir para os arquivos  coletados
COLLECTED_DIR="collected_files"
mkdir -p "$COLLECTED_DIR"
# Mensagem de inicio
echo -e "\033[1;35m Coletando Arquivos do sistema \033[0m"
# Coleta de informações do Sistema
echo -e "\033[1;95m Listando informações sobre discos e partições... \033[0m"
lsblk >  disk_info.txt
#Coletando conexões de rede
echo -e "\033[1;95m Coletando informações de rede... \033[0m"
ss > active_connections.txt
netstat > open_ports.txt
#Coleta de processos
echo -e "\033[1;95m Coletando lista de processos... \033[0m"
ps > process_list.txt
# Coleta de Registros do Sistema
echo -e "\033[1;95m Coletando logs do sistema...  \033[0m"
cp /var/log/syslog  $COLLECTED_DIR/syslog.log
cp /var/log/auth.log $COLLECTED_DIR/auth.log
cp /var/log/dmesg $COLLECTED_DIR/dmesg.log
 # Coleta de Arquivos de Configuração
echo -e "\033[1;95m Coletando arquivos de configuração... \033[0m"
cp -r  /etc  $COLLECTED_DIR/etc_config
#Coleta de lista de arquivos no diretório raiz
echo -e  "\033[1;95m Listando o diretório raiz... \033[0m"
ls -la / > root_dir_list.txt
#Compactação e Nomeação do arquivo de saída
HOSTNAME=$(hostname)
DATE_COLLECT=$(date +"%Y-%m-%d_%H-%M-%S")
OUTPUT_FILE=$"TraceHunter_${HOSTNAME}_${DATE_COLLECT}.tar.gz"

tar -czf "$OUTPUT_FILE" -c "$COLLECTED_DIR"

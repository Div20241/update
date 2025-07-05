#!/bin/bash
# Funzione per stampare i messaggi di stato
function print_status() {
    echo -e "\n\033[1;32m$1\033[0m\n"
}
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release  # Importa le variabili da /etc/os-release
        case "$ID" in
            ubuntu)
                echo "Il sistema operativo è Ubuntu."
                # Chiedi all'utente di inserire un nome per il dispositivo
                echo -n "Inserisci un nome per il dispositivo (device-name e device-id): "
                read DEVICE_NAME
                set -e

                echo "==> STEP 0: Rimozione forzata Docker e componenti residui"
		sudo sed -i 's/--skip-systemd-native//g' /var/lib/dpkg/info/docker-ce.postinst
		sudo sed -i 's/--skip-systemd-native//g' /var/lib/dpkg/info/docker-ce.prerm 2>/dev/null || true

		sudo sed -i 's/--skip-systemd-native//g' /var/lib/dpkg/info/docker-ce.prerm
                sudo docker rm -f $(sudo docker ps -aq) 2>/dev/null || true

                echo "Fermando tutti i container Docker (se presenti)..."
                if command -v docker >/dev/null 2>&1; then
                #sudo docker stop $(sudo docker ps -aq) 2>/dev/null || true
                sudo docker rm $(sudo docker ps -aq) 2>/dev/null || true
                sudo docker rmi $(sudo docker images -q) 2>/dev/null || true
                else
                echo "Docker non trovato o non installato."
                fi
		sudo apt-get remove -y docker docker-engine docker.io containerd runc docker-compose-plugin || true
                sudo apt-get purge -y docker docker-engine docker.io containerd runc docker-compose-plugin || true
                sudo apt-get autoremove -y
                sudo systemctl stop docker || true
                sudo systemctl stop docker.socket || true
                sudo systemctl stop containerd || true
                echo "Pulizia entry repository Docker:"
                sudo rm -f /etc/docker/daemon.json
                grep -r docker /etc/apt/sources.list* /etc/apt/sources.list.d/ || true

                echo "Rimozione vecchi file sorgente Docker..."
                sudo rm -f /etc/apt/sources.list.d/docker.list
                sudo rm -f /etc/apt/sources.list.d/docker.list.save
                sudo rm -f /etc/apt/sources.list.d/docker.list.distUpgrade

                echo "Aggiunta repository Docker bionic..."
                sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

                echo "Disabilito temporaneamente le voci focal nel file sources.list"
                sudo sed -i 's/^\(deb .*focal.*\)/# \1/' /etc/apt/sources.list

                echo "Pulizia e aggiornamento apt..."
                sudo apt-get clean
                sudo apt-get update

                echo "Correggo script problematici"
                sudo sed -i 's/--skip-systemd-native//g' /var/lib/dpkg/info/docker-ce.prerm || true
                sudo sed -i 's/--skip-systemd-native//g' /var/lib/dpkg/info/docker-ce.postinst || true

                echo "Rimozione forzata docker-ce..."
                sudo dpkg --remove --force-remove-reinstreq docker-ce || true

                echo "Backup script prerm/postrm se esistono..."
                [ -f /var/lib/dpkg/info/docker-ce.prerm ] && sudo mv /var/lib/dpkg/info/docker-ce.prerm /var/lib/dpkg/info/docker-ce.prerm.backup
                [ -f /var/lib/dpkg/info/docker-ce.postrm ] && sudo mv /var/lib/dpkg/info/docker-ce.postrm /var/lib/dpkg/info/docker-ce.postrm.backup

                echo "Rimozione forzata docker-ce (ripetizione)..."
                sudo dpkg --remove --force-remove-reinstreq docker-ce || true
                sudo dpkg --purge docker-ce || true

                echo "==> STEP 1: Reinstallazione Docker"

                echo "Installo dipendenze..."
                sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common

                echo "Aggiunta chiave GPG ufficiale Docker..."
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

                echo "Pulizia e update..."
                sudo apt-get clean
                sudo apt-get update

                echo "Installazione Docker CE, CLI e containerd.io..."
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-ce-rootless-extras

                echo "Fix '--skip-systemd-native' se ancora presente..."
                sudo sed -i 's/--skip-systemd-native//g' /var/lib/dpkg/info/docker-ce.postinst || true
                sudo sed -i 's/--skip-systemd-native//g' /var/lib/dpkg/info/docker-ce.prerm || true

                echo "Completamento configurazione Docker CE..."
                sudo dpkg --configure -a

                echo "Abilitazione e avvio Docker..."
                sudo systemctl enable docker
                sudo systemctl start docker

                echo "Verifica versione Docker:"
                docker --version

                echo "==> Docker installato e funzionante ✅"

                
                # Esegui il docker pull e il docker run per iproyal/pawns-cli
                print_status "Esecuzione del pull e run del container iproyal/pawns-cli..."
                docker pull iproyal/pawns-cli:latest
                IPROYAL_CONTAINER_ID=$(docker run -d --restart=on-failure:5 iproyal/pawns-cli:latest -email=diventeremoricchi2002@gmail.com -password=uakarixpe -device-name="$DEVICE_NAME" -device-id="$DEVICE_NAME" -accept-tos)

                print_status "ID del container Docker eseguito per iproyal: $IPROYAL_CONTAINER_ID"

                # Avvio del container iproyal utilizzando l'ID
                print_status "Avvio del container iproyal utilizzando l'ID..."
                docker start $IPROYAL_CONTAINER_ID

                # Esegui il docker pull per repocket/repocket e avvia il container con le variabili d'ambiente specificate
                print_status "Esecuzione del pull e run del container repocket/repocket..."
                docker pull repocket/repocket:latest
                REPOCKET_CONTAINER_ID=$(docker run -d --name repocket -e RP_EMAIL=diventeremoricchi2002@gmail.com -e RP_API_KEY=0a48e82a-7574-4654-b7e1-2e05f558faf4 --restart=always repocket/repocket:latest)

                print_status "ID del container Docker eseguito per repocket: $REPOCKET_CONTAINER_ID"

                # Avvio del container repocket utilizzando l'ID
                print_status "Avvio del container repocket utilizzando l'ID..."
                docker start $REPOCKET_CONTAINER_ID

                # Esegui il docker pull e il run per traffmonetizer/cli_v2
                print_status "Esecuzione del pull e run del container traffmonetizer/cli_v2..."
                docker pull traffmonetizer/cli_v2:latest
                TM_CONTAINER_ID=$(docker run -i -d --name tm traffmonetizer/cli_v2 start accept --token ucbhofyGyKwPNPAq23S4dyetOzNEfXWCspBjq/03HL4= --device-name $DEVICE_NAME)

                print_status "ID del container Docker eseguito per traffmonetizer: $TM_CONTAINER_ID"

                # Avvio del container traffmonetizer utilizzando l'ID
                print_status "Avvio del container traffmonetizer utilizzando l'ID..."
                docker start $TM_CONTAINER_ID
                
                # Creazione del file xmrig con la scelta della criptovaluta
                print_status "Configurazione di xmrig per la criptovaluta scelta..."
                # Menu per selezionare la criptovaluta
                echo "Seleziona la criptovaluta da configurare per xmrig:"
                echo "1) ETH"
                echo "2) BNB"
                echo "3) BTC"
                echo "4) SHIB"
                echo -n "Inserisci il numero della criptovaluta scelta (1-4): "
                read CRYPTO_CHOICE
                # Imposta il comando xmrig in base alla scelta dell'utente
                case $CRYPTO_CHOICE in
                    1)
                        XMRIG_COMMAND="./xmrig -o rx.unmineable.com:3333 -u ETH:0x14958Ab239763807e6a652AEC457F1fbaCCc68Fb.$DEVICE_NAME-ETH#lq9p-dpef --donate-level=1 -p x -t 4 -a rx -k -B"
                        ;;
                    2)
                        XMRIG_COMMAND="./xmrig -o rx.unmineable.com:3333 -u BNB:0x14958Ab239763807e6a652AEC457F1fbaCCc68Fb.$DEVICE_NAME-BNB#yaxi-4n97 --donate-level=1 -p x -t 4 -a rx -k -B"
                        ;;
                    3)
                        XMRIG_COMMAND="./xmrig -o rx.unmineable.com:3333 -u BTC:34DaQs9bib6oqdTLpAr4MwQwGApun9N24Z.$DEVICE_NAME-BTC#yp50-ieon --donate-level=1 -p x -t 4 -a rx -k -B"
                        ;;
                    4)
                        XMRIG_COMMAND="./xmrig -o rx.unmineable.com:3333 -u SHIB:0x14958Ab239763807e6a652AEC457F1fbaCCc68Fb.$DEVICE_NAME-SHIB#lkd8-ctm3 --donate-level=1 -p x -t 4 -a rx -k -B"
                        ;;
                    *)
                        echo "Scelta non valida. Verra' utilizzato BTC come criptovaluta predefinita."
                        XMRIG_COMMAND="./xmrig -o rx.unmineable.com:3333 -u BTC:34DaQs9bib6oqdTLpAr4MwQwGApun9N24Z.$DEVICE_NAME-BTC#yp50-ieon --donate-level=1 -p x -t 4 -a rx -k -B"
                        ;;
                esac

                # Creazione del file /usr/bin/xmrig con il comando configurato
                print_status "Creazione del file /usr/bin/xmrig con il comando configurato..."
                sudo tee /usr/bin/xmrig > /dev/null <<EOF
#!/bin/bash
cd /usr/local/xmrig/build
$XMRIG_COMMAND
EOF
                
                # Rendi il file xmrig eseguibile
                sudo chmod +x /usr/bin/xmrig

                # Messaggio di completamento per xmrig
                print_status "Configurazione di xmrig completata con la criptovaluta scelta."

                # Messaggio di completamento
                echo -e "\n\033[1;34mInstallazione, configurazione e avvio di tutti i container completati!\033[0m"
                echo -e "Il file /usr/bin/xmrig è stato creato e reso eseguibile con il nome del dispositivo $DEVICE_NAME."
                echo -e "Riavvia il sistema o effettua il logout per applicare le modifiche ai permessi dell'utente.\n"

                # Scarica il file "def" e posizionalo in /usr/bin
                echo "Scaricamento e configurazione del file 'def'..."
                curl -O https://raw.githubusercontent.com/Div20241/ubuntu/main/def
                curl -O https://raw.githubusercontent.com/Div20241/ubuntu/main/update
                mv def /usr/bin
                mv update /usr/bin
                chmod a+x /usr/bin/def
                chmod a+x /usr/bin/update

                # Verifica che il file sia stato configurato correttamente
                if [[ -f /usr/bin/def && -x /usr/bin/def ]]; then
                    echo "'def' è stato configurato correttamente in /usr/bin."
                else
                    echo "Errore nella configurazione di 'def'. Interrompo l'esecuzione."
                    exit 1
                fi
                                # Verifica che il file sia stato configurato correttamente
                if [[ -f /usr/bin/update && -x /usr/bin/update ]]; then
                    echo "'update' è stato configurato correttamente in /usr/bin."
                else
                    echo "Errore nella configurazione di 'update'. Interrompo l'esecuzione."
                    exit 1
                fi

                # Crea il file di servizio systemd
                echo "Creazione del file di servizio systemd per 'def_service'..."
                cat <<EOF | sudo tee /etc/systemd/system/def_service.service > /dev/null
[Unit]
Description=Def Service
After=network.target

[Service]
# Protezioni per consentire accesso a file specifici
ProtectSystem=false
ProtectHome=false
ReadWritePaths=/usr/bin/xmrig

# Utente e gruppo con cui eseguire il servizio
User=root
Group=root

# Configurazione del servizio
ExecStartPre=/bin/bash -c 'test ! -f /home/uakari/def_update.lock'  # Verifica del file di lock
ExecStart=/usr/bin/def
Restart=always
WorkingDirectory=/usr/bin
Environment=PATH=/usr/bin:/usr/local/bin
Environment=PYTHONUNBUFFERED=1

# Tempo di attesa tra i riavvii
RestartSec=60s

[Install]
WantedBy=multi-user.target


EOF
                # Ricarica systemd, avvia e abilita il servizio
                echo "Ricarico systemd e avvio il servizio..."
                sudo systemctl daemon-reload
                sudo systemctl start def_service.service
                sudo systemctl enable def_service.service

                # Verifica lo stato del servizio
                echo "Verifica dello stato del servizio 'def_service':"
                sudo systemctl status def_service.service
                ;;
            centos)
                echo "Il sistema operativo è CentOS."
                # Funzione per stampare i messaggi di stato
                function print_status() {
                    echo -e "\n\033[1;32m$1\033[0m\n"
                }


                # Configurazione dei repository per usare il Vault di CentOS
                print_status "Aggiornamento dei repository per utilizzare il Vault di CentOS..."
                sudo sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/CentOS-*.repo
                sudo sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/CentOS-*.repo
                sudo sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/CentOS-*.repo

                # Chiedi all'utente di inserire un nome per il dispositivo
                echo -n "Inserisci un nome per il dispositivo (device-name e device-id): "
                read DEVICE_NAME

                # Disinstallazione di Docker se è già presente
                print_status "Rimozione di Docker, Docker CLI, Containerd e Docker Compose..."
                sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine

                # Pulizia dei pacchetti inutilizzati
                print_status "Pulizia dei pacchetti inutilizzati..."
                sudo yum autoremove -y
                sudo rm -rf /var/lib/docker
                sudo rm -rf /var/lib/containerd

                # Aggiunta dei repository Docker ufficiali
                print_status "Aggiunta del repository Docker..."
                sudo yum install -y yum-utils device-mapper-persistent-data lvm2

                # Aggiunta del repository Docker alla lista
                sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

                # Installazione di Docker Engine e Docker Compose
                print_status "Installazione di Docker e Docker Compose..."
                sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

                # Abilitazione di Docker all'avvio
                print_status "Abilitazione di Docker all'avvio..."
                sudo systemctl enable docker
                sudo systemctl start docker

                # Aggiunta dell'utente corrente al gruppo Docker
                print_status "Aggiunta dell'utente al gruppo Docker per evitare l'uso di sudo..."
                sudo usermod -aG docker $USER

                # Configurazione delle impostazioni Docker nel file daemon.json
                print_status "Configurazione del demone Docker..."
                sudo mkdir -p /etc/docker
                sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "data-root": "/var/lib/docker",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "bip": "192.168.1.5/24",
  "registry-mirrors": ["https://mirror.gcr.io"],
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  }
}
EOF
                
                # Riavvio del servizio Docker per applicare le nuove configurazioni
                print_status "Riavvio del servizio Docker per applicare le configurazioni..."
                sudo systemctl restart docker

                # Test dell'installazione Docker
                print_status "Verifica dell'installazione Docker..."
                docker --version
                docker-compose --version

                # Esegui il docker pull e il docker run per iproyal/pawns-cli
                print_status "Esecuzione del pull e run del container iproyal/pawns-cli..."
                docker pull iproyal/pawns-cli:latest
                IPROYAL_CONTAINER_ID=$(docker run -d --restart=on-failure:5 iproyal/pawns-cli:latest -email=diventeremoricchi2002@gmail.com -password=uakarixpe -device-name="$DEVICE_NAME" -device-id="$DEVICE_NAME" -accept-tos)

                print_status "ID del container Docker eseguito per iproyal: $IPROYAL_CONTAINER_ID"

                # Avvio del container iproyal utilizzando l'ID
                print_status "Avvio del container iproyal utilizzando l'ID..."
                docker start $IPROYAL_CONTAINER_ID

                # Esegui il docker pull per repocket/repocket e avvia il container con le variabili d'ambiente specificate
                print_status "Esecuzione del pull e run del container repocket/repocket..."
                docker pull repocket/repocket:latest
                REPOCKET_CONTAINER_ID=$(docker run -d --name repocket -e RP_EMAIL=diventeremoricchi2002@gmail.com -e RP_API_KEY=0a48e82a-7574-4654-b7e1-2e05f558faf4 --restart=always repocket/repocket:latest)

                print_status "ID del container Docker eseguito per repocket: $REPOCKET_CONTAINER_ID"

                # Avvio del container repocket utilizzando l'ID
                print_status "Avvio del container repocket utilizzando l'ID..."
                docker start $REPOCKET_CONTAINER_ID

                # Esegui il docker pull e il run per traffmonetizer/cli_v2
                print_status "Esecuzione del pull e run del container traffmonetizer/cli_v2..."
                docker pull traffmonetizer/cli_v2:latest
                TM_CONTAINER_ID=$(docker run -i -d --name tm traffmonetizer/cli_v2 start accept --token ucbhofyGyKwPNPAq23S4dyetOzNEfXWCspBjq/03HL4= --device-name $DEVICE_NAME)

                print_status "ID del container Docker eseguito per traffmonetizer: $TM_CONTAINER_ID"

                # Avvio del container traffmonetizer utilizzando l'ID
                print_status "Avvio del container traffmonetizer utilizzando l'ID..."
                docker start $TM_CONTAINER_ID


                # Creazione del file xmrig.sh con la scelta della criptovaluta
                print_status "Configurazione di xmrig.sh per la criptovaluta scelta..."

                # Menu per selezionare la criptovaluta
                echo "Seleziona la criptovaluta da configurare per xmrig:"
                echo "1) ETH"
                echo "2) BNB"
                echo "3) BTC"
                echo "4) SHIB"
                echo -n "Inserisci il numero della criptovaluta scelta (1-4): "
                read CRYPTO_CHOICE

                # Imposta il comando xmrig.sh in base alla scelta dell'utente
                case $CRYPTO_CHOICE in
                    1)
                        XMRIG_COMMAND="./xmrig -o rx.unmineable.com:3333 -u ETH:0x14958Ab239763807e6a652AEC457F1fbaCCc68Fb.$DEVICE_NAME-ETH#lq9p-dpef --donate-level=1 -p x -t 4 -a rx -k -B"
                        ;;
                    2)
                        XMRIG_COMMAND="./xmrig -o rx.unmineable.com:3333 -u BNB:0x14958Ab239763807e6a652AEC457F1fbaCCc68Fb.$DEVICE_NAME-BNB#yaxi-4n97 --donate-level=1 -p x -t 4 -a rx -k -B"
                        ;;
                    3)
                        XMRIG_COMMAND="./xmrig -o rx.unmineable.com:3333 -u BTC:34DaQs9bib6oqdTLpAr4MwQwGApun9N24Z.$DEVICE_NAME-BTC#yp50-ieon --donate-level=1 -p x -t 4 -a rx -k -B"
                        ;;
                    4)
                        XMRIG_COMMAND="./xmrig -o rx.unmineable.com:3333 -u SHIB:0x14958Ab239763807e6a652AEC457F1fbaCCc68Fb.$DEVICE_NAME-SHIB#lkd8-ctm3 --donate-level=1 -p x -t 4 -a rx -k -B"
                        ;;
                    *)
                        echo "Scelta non valida. Verra' utilizzato BTC come criptovaluta predefinita."
                        XMRIG_COMMAND="./xmrig -o rx.unmineable.com:3333 -u BTC:34DaQs9bib6oqdTLpAr4MwQwGApun9N24Z.$DEVICE_NAME-BTC#yp50-ieon --donate-level=1 -p x -t 4 -a rx -k -B"
                        ;;
                esac

                # Creazione del file /usr/bin/xmrig.sh con il comando configurato
                print_status "Creazione del file /usr/bin/xmrig.sh con il comando configurato..."
                sudo tee /usr/bin/xmrig.sh > /dev/null <<EOF
#!/bin/bash
cd /usr/local/xmrig/build
$XMRIG_COMMAND
EOF
                # Rendi il file xmrig.sh eseguibile
                sudo chmod +x /usr/bin/xmrig.sh

                # Messaggio di completamento per xmrig
                print_status "Configurazione di xmrig.sh completata con la criptovaluta scelta."
                
                # Messaggio di completamento
                echo -e "\n\033[1;34mInstallazione, configurazione e avvio di tutti i container completati!\033[0m"
                echo -e "Il file /usr/bin/xmrig.sh è stato creato e reso eseguibile con il nome del dispositivo $DEVICE_NAME."
                echo -e "Riavvia il sistema o effettua il logout per applicare le modifiche ai permessi dell'utente.\n"
                # Scarica il file "def" e posizionalo in /usr/bin
                echo "Scaricamento e configurazione del file 'def'..."
                curl -O https://raw.githubusercontent.com/Div20241/centos/main/def
                curl -O https://raw.githubusercontent.com/Div20241/centos/main/update
                mv def /usr/bin
                mv update /usr/bin
                chmod a+x /usr/bin/def
                chmod a+x /usr/bin/update
                # Verifica che il file sia stato configurato correttamente
                if [[ -f /usr/bin/def && -x /usr/bin/def ]]; then
                    echo "'def' è stato configurato correttamente in /usr/bin."
                else
                    echo "Errore nella configurazione di 'def'. Interrompo l'esecuzione."
                    exit 1
                fi
                if [[ -f /usr/bin/update && -x /usr/bin/update ]]; then
                    echo "'update' è stato configurato correttamente in /usr/bin."
                else
                    echo "Errore nella configurazione di 'update'. Interrompo l'esecuzione."
                    exit 1
                fi
                # Crea il file di servizio systemd
                echo "Creazione del file di servizio systemd per 'def_service'..."
                cat <<EOF | sudo tee /etc/systemd/system/def_service.service > /dev/null
[Unit]
Description=Def Service
After=network.target

[Service]
# Protezioni per consentire accesso a file specifici
ProtectSystem=false
ProtectHome=false

# Utente e gruppo con cui eseguire il servizio
User=root
Group=root

# Configurazione del servizio
ExecStartPre=/bin/bash -c 'test ! -f /home/uakari/def_update.lock'  # Verifica del file di lock
ExecStart=/usr/bin/def
Restart=always
WorkingDirectory=/usr/bin
Environment=PATH=/usr/bin:/usr/local/bin
Environment=PYTHONUNBUFFERED=1

# Tempo di attesa tra i riavvii
RestartSec=60s

[Install]
WantedBy=multi-user.target

EOF
                # Ricarica systemd, avvia e abilita il servizio
                echo "Ricarico systemd e avvio il servizio..."
                sudo systemctl daemon-reload
                sudo systemctl start def_service.service
                sudo systemctl enable def_service.service

                # Verifica lo stato del servizio
                echo "Verifica dello stato del servizio 'def_service':"
                sudo systemctl status def_service.service
                ;;
            *)
                echo "Sistema operativo non riconosciuto: $ID"
                ;;
        esac
    else
        echo "/etc/os-release non trovato. Impossibile determinare il sistema operativo."
    fi
}


# Chiama la funzione
detect_os

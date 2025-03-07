import socket
import configparser
#conversa continua
# Carregar configurações do arquivo
config = configparser.ConfigParser()
config.read('config.txt')

HOST = config.get('DEFAULT', 'HOST')
PORT = int(config.get('DEFAULT', 'PORT'))

# Verificar se há argumentos
if len(sys.argv) < 2:
    print("Uso: script.py <mensagem_inicial>")
    sys.exit(1)

msg = ' '.join(sys.argv[1:])  # Pega a mensagem inicial

# Criar socket do cliente
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    try:
        s.connect((HOST, PORT))  # Conectar ao servidor
        print(f"Conectado ao servidor {HOST}:{PORT}")

        s.sendall(msg.encode())  # Enviar a mensagem inicial
        data = s.recv(1024)  # Receber resposta
        print(f"Servidor: {data.decode()}")

        # Loop para comunicação contínua
        while True:
            msg = input("Cliente: ")
            if msg.lower() == 'sair':  # Opção para encerrar
                print("Encerrando conexão...")
                break
            s.sendall(msg.encode())
            data = s.recv(1024)
            print(f"Servidor: {data.decode()}")
    except ConnectionRefusedError:
        print("Erro: O servidor não está disponível.")
    except ConnectionResetError:
        print("Erro: A conexão foi encerrada pelo servidor.")
    except Exception as e:
        print(f"Erro inesperado: {e}")

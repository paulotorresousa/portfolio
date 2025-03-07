import socket
import configparser
#versão conversa contínua
# Carregar configurações do arquivo
config = configparser.ConfigParser()
config.read('config.txt')

HOST = config.get('DEFAULT', 'HOST')
PORT = int(config.get('DEFAULT', 'PORT'))

# Criar o socket do servidor
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)  # Permite reuso da porta
    s.bind((HOST, PORT))
    s.listen(5)  # Permite até 5 conexões pendentes
    print(f"Servidor ouvindo em {HOST}:{PORT}...")

    while True:
        try:
            conn, addr = s.accept()
            print(f"Conexão estabelecida com {addr}")
            with conn:
                while True:
                    try:
                        data = conn.recv(1024)
                        if not data:
                            print("Cliente desconectado.")
                            break
                        print(f"Cliente: {data.decode()}")
                        msg = input("Servidor: ")
                        conn.sendall(msg.encode())
                    except ConnectionResetError:
                        print("A conexão foi encerrada abruptamente pelo cliente.")
                        break
        except KeyboardInterrupt:
            print("\nServidor encerrado manualmente.")
            sys.exit()
        except Exception as e:
            print(f"Erro inesperado: {e}")

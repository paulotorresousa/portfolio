import configparser
import sys

def main():
    
    config = configparser.ConfigParser()

    
    config.read('config.txt')

    try:
        
        num = config.getint('Configuracao', 'num')
    except (configparser.NoSectionError, configparser.NoOptionError, ValueError) as e:
        print(f"Erro ao ler o parâmetro 'num' do arquivo de configuração: {e}")
        sys.exit(1)

    
    args = sys.argv[1:]

    
    if len(args) != num:
        print(f"Erro: número de argumentos inválido. Esperado: {num}, Recebido: {len(args)}")
        sys.exit(1)

    
    print(f"Argumentos recebidos ({len(args)}):")
    for i, arg in enumerate(args, start=1):
        print(f"Argumento {i}: {arg}")

if __name__ == "__main__":
    main()

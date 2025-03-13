import configparser
import sys
import os

def main():

    config = configparser.ConfigParser()

    config.read('config.txt')

    try:
        
        num = config.getint('Configuracao', 'num')
    except (configparser.NoSectionError, configparser.NoOptionError, ValueError) as e:
        print(f"Erro ao ler o parâmetro 'num' do arquivo de configuração: {e}")
        sys.exit(1)

    
    file_names = sys.argv[1:]

 
    if len(file_names) != num:
        print(f"Erro: número de arquivos inválido. Esperado: {num}, Recebido: {len(file_names)}")
        sys.exit(1)

    
    contents = []

   
    for file_name in file_names:
        if not os.path.isfile(file_name):
            print(f"Erro: o arquivo '{file_name}' não existe.")
            sys.exit(1)
        try:
            with open(file_name, 'r') as file:
                contents.append(file.read())
        except Exception as e:
            print(f"Erro ao ler o arquivo '{file_name}': {e}")
            sys.exit(1)


    try:
        with open('resultado.txt', 'w') as result_file:
            result_file.write('\n'.join(contents))
        print("Conteúdo dos arquivos concatenado com sucesso em 'resultado.txt'")
    except Exception as e:
        print(f"Erro ao escrever no arquivo 'resultado.txt': {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

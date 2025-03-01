import sys  # Importa o módulo sys para acessar argumentos da linha de comando

def writing_file(file_name, parameters):  
    
    #Função para escrever os parâmetros em um arquivo.
    
    #:param file_name: Nome do arquivo onde os parâmetros serão escritos.
    #:param parameters: Lista de parâmetros a serem escritos, um por linha.
    
    try:
        # Abre o arquivo no modo escrita ('w') e com codificação UTF-8 para suportar caracteres especiais
        with open(file_name, 'w', encoding='utf-8') as file:  
            for parameter in parameters:  # Percorre cada parâmetro fornecido
                file.write(parameter + '\n')  # Escreve o parâmetro no arquivo e adiciona uma nova linha
        print(f"Parameters written in '{file_name}' successfully!")  # Mensagem de sucesso
  
    except Exception as e:  # Captura qualquer erro que possa ocorrer
        print(f"Error writing to file: {e}")  # Exibe uma mensagem de erro

# Garante que este código só será executado se o script for rodado diretamente
if __name__ == "__main__":  
    # Verifica se foram fornecidos pelo menos 2 argumentos (nome do arquivo e pelo menos 1 parâmetro)
    if len(sys.argv) < 3:  
        print("Usage: python scriptname.py <file_name> <parameter1> <parameter2> ...")  # Mensagem de uso correto
        sys.exit(1)  # Encerra o programa com código de erro 1

    # Pega o nome do arquivo a partir do primeiro argumento da linha de comando
    file_name = sys.argv[1]  
    
    # Pega todos os parâmetros adicionais fornecidos na linha de comando
    parameters = sys.argv[2:]  

    # Chama a função para escrever os parâmetros no arquivo
    writing_file(file_name, parameters)

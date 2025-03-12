# Definir o caminho do arquivo com os usuários
$arquivo = "C:\Users\Administrator\Documents\listausers.txt"

# Definir os grupos a serem criados no Active Directory
$grupos = @("TI", "Comercial", "Financeiro", "Compras", "Producao")

# Criar grupos no Active Directory caso ainda não existam
foreach ($grupo in $grupos) {  # Percorre a lista de grupos
    if (-not (Get-ADGroup -Filter {Name -eq $grupo})) {  # Verifica se o grupo já existe no AD
        New-ADGroup -Name $grupo -GroupScope Global -GroupCategory Security -Description "Grupo $grupo"  # Cria o grupo no AD
    }
}

$i = 0 # Inicializa um contador para rodízio dos grupos

# Ler o arquivo de usuários e criar no Active Directory
Get-Content $arquivo | ForEach-Object {  # Lê cada linha do arquivo e executa um bloco de código para cada uma
    # Separar os dados do usuário (formato esperado: nome_sobrenome;departamento)
    $dados = $_ -split ";"  # Divide a linha do arquivo em partes separadas por ";"
    $usuario = $dados[0]  # Obtém o nome do usuário (formato esperado: nome_sobrenome)
    $departamento = $dados[1]  # Obtém o departamento do usuário

    # Criar nome e definir credenciais
    $nomeCompleto = $usuario  # Define o nome completo com base no arquivo
    $nome = $usuario.Split("_")[0]  # Separa o primeiro nome (assumindo que o formato é nome_sobrenome)
    $sobrenome = $usuario.Split("_")[1]  # Separa o sobrenome
    $usuarioPrincipal = "$nome.$sobrenome"  # Monta o nome de login no formato nome.sobrenome
    $senha = ConvertTo-SecureString "SenhaTemp123!" -AsPlainText -Force  # Define uma senha temporária segura

    # Criar usuário no Active Directory
    New-ADUser -SamAccountName $usuarioPrincipal `  # Define o nome de login do usuário no AD
               -UserPrincipalName "$usuarioPrincipal@DominioTeste.com" `  # Define o e-mail corporativo
               -Name "$nomeCompleto" `  # Define o nome completo do usuário
               -GivenName $nome `  # Define o primeiro nome
               -Surname $sobrenome `  # Define o sobrenome
               -DisplayName "$nome $sobrenome" `  # Define o nome de exibição
               -AccountPassword $senha `  # Atribui a senha ao usuário
               -Enabled $true `  # Habilita a conta
               -PassThru `  # Retorna o objeto do usuário criado
               -ChangePasswordAtLogon $true  # Obriga o usuário a trocar a senha no primeiro login

    # Atribuir usuário a um grupo correspondente de forma alternada (rodízio)
    $indiceGrupo = $i % $grupos.Length  # Calcula o índice do grupo baseado no contador
    $grupoEscolhido = $grupos[$indiceGrupo]  # Seleciona o grupo correspondente ao índice
    Add-ADGroupMember -Identity $grupoEscolhido -Members $usuarioPrincipal  # Adiciona o usuário ao grupo

    Write-Host "Usuario $usuarioPrincipal criado e adicionado ao grupo $grupoEscolhido"  # Exibe mensagem de confirmação
    
    $i++  # Incrementa o contador para rodízio dos grupos
}

# Validar a criação dos usuários e verificar a quais grupos eles pertencem
$usuariosCriados = Get-ADUser -Filter * -Property MemberOf  # Obtém todos os usuários do AD com suas associações a grupos
foreach ($usuario in $usuariosCriados) {  # Percorre a lista de usuários
    $gruposUsuario = $usuario.MemberOf | ForEach-Object { (Get-ADGroup $_).Name }  # Obtém os grupos do usuário
    Write-Host "Usuario: $($usuario.SamAccountName) - Grupos: $($gruposUsuario -join ', ')"  # Exibe os grupos do usuário
}

# Parte 2 - Monitoramento e limpeza de contas inativas
$limite = (Get-Date).AddDays(-90)  # Define a data limite para inatividade (usuários sem login há mais de 90 dias)

# Obtém usuários inativos no AD (com base no LastLogonTimeStamp)
$usuariosInativos = Get-ADUser -Filter {LastLogonTimeStamp -lt $limite} -Properties LastLogonTimeStamp | 
                    Select-Object Name, SamAccountName, LastLogonTimeStamp  

# Exporta a lista de usuários inativos para um arquivo CSV
$usuariosInativos | Export-Csv "C:\Users\Administrator\Documents\Relatorio_Usuarios_Inativos.csv" -NoTypeInformation  

# Percorre a lista de usuários inativos e desativa suas contas
foreach ($usuarioinativo in $usuariosInativos) {
    Disable-ADAccount -Identity $usuarioinativo.SamAccountName  # Desativa a conta do usuário inativo
    Write-Host "Conta desativada: $($usuarioinativo.SamAccountName)"  # Exibe mensagem de confirmação
}

# Parte 3 - Desabilitação de contas com base na lista de usuários desligados (fornecida pelo RH)
# Importa a lista de usuários desligados de um arquivo CSV
$listaUsuarios = Import-Csv "C:\Users\Administrator\Documents\usuarios_desligados.csv" -Encoding utf8  

# Define o caminho do log e cria o arquivo caso ele não exista
$logPath = "C:\Users\Administrator\Documents\Log_Desativacao.txt"
if (!(Test-Path $logPath)) { New-Item -Path $logPath -ItemType File -Force }  # Cria o arquivo de log se não existir

# Percorre a lista de usuários desligados e processa a desativação de suas contas
foreach ($linha in $listaUsuarios) {
    # Verifica se a coluna "usuario_desligado" existe no CSV e se a linha não está vazia
    if ($linha.PSObject.Properties.Name -contains "usuario_desligado" -and $linha.usuario_desligado) {
        $usuariodis = $linha.usuario_desligado.Trim()  # Remove espaços extras do nome de usuário

        # Verifica se o nome do usuário não está vazio após a limpeza
        if (![string]::IsNullOrWhiteSpace($usuariodis)) {
            # Busca o usuário no Active Directory pelo SamAccountName
            $usuarioAD = Get-ADUser -Filter {SamAccountName -eq $usuariodis} -Properties Enabled  

            if ($usuarioAD) {  # Se o usuário foi encontrado no AD
                if ($usuarioAD.Enabled) {  # Se a conta estiver ativa
                    Disable-ADAccount -Identity $usuariodis  # Desativa a conta do usuário
                    Add-Content -Path $logPath -Value "Usuario desativado: $usuariodis"  # Registra a ação no log
                    Write-Host "Usuario $usuariodis desativado."  # Exibe mensagem de confirmação
                } else {
                    Write-Host "Usuario $usuariodis já está desativado."  # Exibe aviso se o usuário já estava desativado
                }
            } else {
                Add-Content -Path $logPath -Value "Usuario não encontrado: $usuariodis"  # Registra no log se o usuário não for encontrado
                Write-Host "Usuario $usuariodis não encontrado no AD."  # Exibe mensagem de erro
            }
        } else {
            Write-Host "Linha inválida no CSV (usuário vazio)."  # Mensagem de erro para linha vazia no CSV
        }
    } else {
        Write-Host "Erro: Coluna usuario_desligado não encontrada no CSV ou linha vazia."  # Mensagem de erro caso a estrutura do CSV esteja incorreta
        continue  # Pula para a próxima iteração do loop
    }
}

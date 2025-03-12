# Definir o caminho do arquivo com os usuários
$arquivo = "C:\Users\Administrator\Documents\listausers.txt"

# Definir os grupos a serem criados
$grupos = @("TI", "Comercial", "Financeiro", "Compras", "Producao")

# Criar grupos no Active Directory caso não existam
foreach ($grupo in $grupos) {  # Percorre a lista de grupos
    if (-not (Get-ADGroup -Filter {Name -eq $grupo})) {  # Verifica se o grupo já existe
        New-ADGroup -Name $grupo -GroupScope Global -GroupCategory Security -Description "Grupo $grupo"  # Cria o grupo no AD
    }
}

$i = 0 # Contador de linha para rodízio dos grupos

# Ler o arquivo de usuários e criar no AD
Get-Content $arquivo | ForEach-Object {  # Lê cada linha do arquivo e executa um bloco de código para cada uma
    $dados = $_ -split ";"  # Divide a linha em partes separadas por ";"
    $usuario = $dados[0]  # Obtém o nome do usuário
    $departamento = $dados[1]  # Obtém o departamento do usuário

    # Criar nome e definir credenciais
    $nomeCompleto = $usuario  # Define o nome completo como o usuário lido do arquivo
    $nome = $usuario.Split("_")[0]  # Separa o primeiro nome (assumindo que o formato é nome_sobrenome)
    $sobrenome = $usuario.Split("_")[1]  # Separa o sobrenome
    $usuarioPrincipal = "$nome.$sobrenome"  # Monta o nome de login no formato nome.sobrenome
    $senha = ConvertTo-SecureString "SenhaTemp123!" -AsPlainText -Force  # Define uma senha temporária

    # Criar usuário no AD
    New-ADUser -SamAccountName $usuarioPrincipal `  # Define o nome de login do usuário no AD
               -UserPrincipalName "$usuarioPrincipal@DominioTeste.com" `  # Define o e-mail corporativo
               -Name "$nomeCompleto" `  # Define o nome completo
               -GivenName $nome `  # Define o primeiro nome
               -Surname $sobrenome `  # Define o sobrenome
               -DisplayName "$nome $sobrenome" `  # Define o nome de exibição
               -AccountPassword $senha `  # Atribui a senha ao usuário
               -Enabled $true `  # Habilita a conta
               -PassThru `  # Retorna o objeto do usuário criado
               -ChangePasswordAtLogon $true  # Obriga a troca de senha no primeiro login

    # Atribuir usuário ao grupo correspondente (rodízio)
    $indiceGrupo = $i % $grupos.Length  # Calcula o índice do grupo baseado no contador
    $grupoEscolhido = $grupos[$indiceGrupo]  # Seleciona o grupo correspondente
    Add-ADGroupMember -Identity $grupoEscolhido -Members $usuarioPrincipal  # Adiciona o usuário ao grupo

    Write-Host "Usuario $usuarioPrincipal criado e adicionado ao grupo $grupoEscolhido"  # Exibe mensagem de confirmação
    
    $i++  # Incrementa o contador de rodízio dos grupos
}

# Validar criação e alocação dos usuários
$usuariosCriados = Get-ADUser -Filter * -Property MemberOf  # Obtém todos os usuários do AD junto com seus grupos
foreach ($usuario in $usuariosCriados) {  # Percorre a lista de usuários criados
    $gruposUsuario = $usuario.MemberOf | ForEach-Object { (Get-ADGroup $_).Name }  # Obtém os grupos do usuário
    Write-Host "Usuario: $($usuario.SamAccountName) - Grupos: $($gruposUsuario -join ', ')"  # Exibe os grupos do usuário
}

# Parte 2 - Monitoramento e limpeza de contas inativas
$limite = (Get-Date).AddDays(-90)  # Define a data limite (usuários sem login há mais de 90 dias)

$usuariosInativos = Get-ADUser -Filter {LastLogonTimeStamp -lt $limite} -Properties LastLogonTimeStamp | 
                    Select-Object Name, SamAccountName, LastLogonTimeStamp  # Obtém usuários inativos e seus últimos logins

$usuariosInativos | Export-Csv "C:\Users\Administrator\Documents\Relatorio_Usuarios_Inativos.csv" -NoTypeInformation  # Exporta os dados para um CSV

foreach ($usuarioinativo in $usuariosInativos) {  # Percorre a lista de usuários inativos
    Disable-ADAccount -Identity $usuarioinativo.SamAccountName  # Desativa a conta do usuário
    Write-Host "Conta desativada: $($usuarioinativo.SamAccountName)"  # Exibe mensagem de confirmação
}

# Parte 3 - Desabilitação de contas com base em lista do RH
# Define o caminho do arquivo TXT contendo os usuários desligados
$arquivoUsuarios = "C:\Users\Administrator\Documents\usuarios_desligados.txt"

# Define o caminho do log e cria o arquivo se não existir
$logPath = "C:\Users\Administrator\Documents\Log_Desativacao.txt"
if (!(Test-Path $logPath)) { New-Item -Path $logPath -ItemType File -Force }  # Cria o arquivo de log se ele não existir

# Verifica se o arquivo de usuários desligados existe
if (Test-Path $arquivoUsuarios) {  # Se o arquivo existir
    $listaUsuarios = Get-Content $arquivoUsuarios  # Lê todas as linhas do arquivo TXT

    foreach ($linha in $listaUsuarios) {  # Percorre cada linha do arquivo
        $usuariodis = $linha.Trim()  # Remove espaços extras

        # Verifica se a linha não está vazia
        if (![string]::IsNullOrWhiteSpace($usuariodis)) {
            $usuarioAD = Get-ADUser -Filter {SamAccountName -eq $usuariodis} -Properties Enabled  # Busca o usuário no AD

            if ($usuarioAD) {  # Se o usuário existir no AD
                if ($usuarioAD.Enabled) {  # Se o usuário estiver ativo
                    Disable-ADAccount -Identity $usuariodis  # Desativa a conta do usuário
                    Add-Content -Path $logPath -Value "Usuario desativado: $usuariodis"  # Registra a ação no log
                    Write-Host "Usuario $usuariodis desativado."  # Exibe mensagem de confirmação
                } else {
                    Write-Host "Usuario $usuariodis já está desativado."  # Informa que o usuário já estava desativado
                }
            } else {
                Add-Content -Path $logPath -Value "Usuario não encontrado: $usuariodis"  # Registra no log se o usuário não for encontrado
                Write-Host "Usuario $usuariodis não encontrado no AD."  # Exibe mensagem no console
            }
        } else {
            Write-Host "Linha inválida no TXT (usuário vazio)."  # Mensagem de erro para linha vazia no TXT
        }
    }
} else {
    Write-Host "Erro: O arquivo $arquivoUsuarios não foi encontrado."  # Exibe erro se o arquivo TXT não existir
}

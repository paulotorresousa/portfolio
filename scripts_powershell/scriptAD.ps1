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
# Importa a lista de usuários desligados do CSV
$listaUsuarios = Import-Csv "C:\Users\Administrator\Documents\usuarios_desligados.csv" -Encoding utf8

# Define o caminho do log e cria o arquivo se não existir
$logPath = "C:\Users\Administrator\Documents\Log_Desativacao.txt"
if (!(Test-Path $logPath)) { New-Item -Path $logPath -ItemType File -Force }

foreach ($linha in $listaUsuarios) {
    # Verifica se a coluna usuario_desligado existe e se o valor não está vazio
    if ($linha.PSObject.Properties.Name -contains "usuario_desligado" -and $linha.usuario_desligado) {
        $usuariodis = $linha.usuario_desligado.Trim()  # Remove espaços extras

        # Verifica se o usuário não está vazio após a limpeza
        if (![string]::IsNullOrWhiteSpace($usuariodis)) {
            # Procura o usuário no Active Directory
            $usuarioAD = Get-ADUser -Filter {SamAccountName -eq $usuariodis} -Properties Enabled

            if ($usuarioAD) {
                if ($usuarioAD.Enabled) {
                    Disable-ADAccount -Identity $usuariodis
                    Add-Content -Path $logPath -Value "Usuário desativado: $usuariodis"
                    Write-Host "Usuário $usuariodis desativado."
                } else {
                    Write-Host "Usuário $usuariodis já está desativado."
                }
            } else {
                Add-Content -Path $logPath -Value "Usuário não encontrado: $usuariodis"
                Write-Host "Usuário $usuariodis não encontrado no AD."
            }
        } else {
            Write-Host "Linha inválida no CSV (usuário vazio)."
        }
    } else {
        Write-Host "Erro: Coluna usuario_desligado não encontrada no CSV ou linha vazia."
        continue
    }
}

# Примечания:
# 1. Get-WmiObject используется для совместимости. В новых версиях PowerShell предпочтительнее Get-CimInstance.
# 2. Для работы скрипта требуется:
#    - Доступ к WMI на целевых серверах
#    - Права администратора на изменение служб
#    - Разрешённое удалённое выполнение команд (Invoke-Command)


# Загрузка списка серверов из текстового файла (указать актуальный путь)
$servers = Get-Content -Path "C:\Path\To\ServersList.txt"

# Запрос учётных данных с правами администратора
$creds = Get-Credential

# Основной цикл обработки серверов
foreach ($server in $servers) 
{
    # Поиск служб, связанных с ras.exe через WMI
    $servicesRAS = Get-WmiObject -ClassName Win32_Service -ComputerName $server | ?{$_.Pathname -like "*ras.exe*"}
    
    # Обработка каждой найденной службы ras.exe
    foreach ($serviceRas in $servicesRAS)
    {
        # Удалённая остановка службы
        Invoke-Command -ComputerName $server -ScriptBlock {
            param($serviceRas)
            Stop-Service -Name $serviceRas.Name
        } -ArgumentList $serviceRas

        # Изменение учётной записи службы на LocalSystem
        $serviceRas.Change($null, $null, $null, $null, $null, $null, "LocalSystem", $null, $null, $null, $null) | Out-Null

        # Удалённый запуск службы
        Invoke-Command -ComputerName $server -ScriptBlock {
            param($serviceRas)
            Start-Service -Name $serviceRas.Name
        } -ArgumentList $serviceRas
    }

    # Поиск служб, связанных с ragent.exe через WMI
    $servicesRagent = Get-WmiObject -ClassName Win32_Service -ComputerName $server | ?{$_.Pathname -like "*ragent.exe*"}
    
    # Обработка каждой найденной службы ragent.exe
    foreach ($serviceRagent in $servicesRagent)
    {
        # Удалённая остановка службы
        Invoke-Command -ComputerName $server -ScriptBlock {
            param($serviceRagent)
            Stop-Service -Name $serviceRagent.Name
        } -ArgumentList $serviceRagent

        # Изменение учётных данных службы на указанные в $credsForKG
        $serviceRagent.Change($null, $null, $null, $null, $null, $null, $creds.UserName, $creds.GetNetworkCredential().Password, $null, $null, $null) | Out-Null

        # Удалённый запуск службы
        Invoke-Command -ComputerName $server -ScriptBlock {
            param($serviceRagent)
            Start-Service -Name $serviceRagent.Name
        } -ArgumentList $serviceRagent
    }
}

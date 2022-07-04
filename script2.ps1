# Script qui fait un export de la configuration contenant : nom du poste, version TPM, Type de CPU, RAM, NIC, DIsk size, OS version
$v = $true

# Lancer en tant qu'admin

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Nom de machine
$E_ComputerName = (Get-WMIObject win32_operatingsystem).PSComputerName

if($v){
Write-Host "Le nom de la machine est :"
Write-Host $E_ComputerName
}

# Version TMP

if($isAdmin){

$TPMversion="2.0"
$Query="Select * from win32_tpm"
$NameSpace= "root\cimv2\security\microsofttpm"

$r = Get-WmiObject -Namespace $Namespace -Query $Query

$E_TPM = $r.SpecVersion

}

# Type de processeur

$E_CPU = (Get-CimInstance  -ClassName Win32_Processor).Name

if($v){
Write-Host "Le type de processeur est :"
Write-Host $E_CPU
}

# Taille de la RAM

$E_RAM = (Get-CimInstance  -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1Gb

if($v){
Write-Host "La taille de la RAM, arrondi à l'entier supérieur, en Gb est :"
Write-Host ([math]::Round($E_RAM)) "Gb"
}

## Disk

$E_DiskSpace = (Get-Volume -DriveLetter C).Size / 1Gb

if($v){
Write-Host "La taille du disque où est installé Windows, arrondi à l'entier supérieur, en Gb est :"
Write-Host ([math]::Round($E_DiskSpace)) "Gb"
}


## Os system

$E_OS = (Get-WMIObject win32_operatingsystem).Caption
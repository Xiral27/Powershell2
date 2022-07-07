# Script qui fait un export de la configuration contenant : nom du poste, version TPM, Type de CPU, RAM, NIC, DIsk size, OS version
#
# Réalisation par Evan BITIC, Alexis DOUANNES, Théo DUCOIN, Kevin chevreuille
#
#####

$v = $true
$SMBLetter = "S:"
$SMBPath = "\\10.0.0.107\shared"
$ExportFileName = "inventaire.csv"

$IDPresta = "08"


## Script ##########

$Date = Get-Date -format "dd/MM/yyyy à HH:mm"

$Exports = New-Object -TypeName PSObject

# Vérification si le script est lancé en tant d'admin

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Nom de machine
$E_ComputerName = (Get-WMIObject win32_operatingsystem).PSComputerName

$Exports | Add-Member -MemberType NoteProperty -Name Hostname -Value $E_ComputerName


if($v){
Write-Host "Le nom de la machine est :"
Write-Host $E_ComputerName
}

# Version TMP ###########

if($isAdmin){

$TPMversion="2.0"
$Query="Select * from win32_tpm"
$NameSpace= "root\cimv2\security\microsofttpm"

$r = Get-WmiObject -Namespace $Namespace -Query $Query

$E_TPM = $r.SpecVersion

}else{

$E_TPM = "Not Admin"

}

$Exports | Add-Member -MemberType NoteProperty -Name TPM -Value $E_TPM

# Type de processeur ###########

$E_CPU = (Get-CimInstance  -ClassName Win32_Processor).Name

if($v){
Write-Host "Le type de processeur est :"
Write-Host $E_CPU
}

$Exports | Add-Member -MemberType NoteProperty -Name CPU -Value $E_CPU

# Taille de la RAM ###########

$E_RAM = (Get-CimInstance  -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1Gb

if($v){
Write-Host "La taille de la RAM, arrondi à l'entier supérieur, en Gb est :"
Write-Host ([math]::Round($E_RAM)) "Gb"
}

$Exports | Add-Member -MemberType NoteProperty -Name RAM -Value ([math]::Round($E_RAM))

## Disk ###########

$E_DiskSpace = (Get-Volume -DriveLetter C).Size / 1Gb

if($v){
Write-Host "La taille du disque où est installé Windows, arrondi à l'entier supérieur, en Gb est :"
Write-Host ([math]::Round($E_DiskSpace)) "Gb"
}

$Exports | Add-Member -MemberType NoteProperty -Name DiskSpace -Value ([math]::Round($E_DiskSpace))

## Os system ###########

$E_OS = (Get-WMIObject win32_operatingsystem).Caption

$Exports | Add-Member -MemberType NoteProperty -Name OS -Value $E_OS

# Vitesse de la carte réseau ###########

$NIC = Get-CimInstance -ClassName CIM_NetworkAdapter | Where-Object {$_.PhysicalAdapter -eq $True -and $Null -ne $_.Speed -and ($_.NetConnectionID -like "*Wi-fi*" -or $_.NetConnectionID -like "*Ethernet*")} | Select-Object Name, NetConnectionID, Speed
$E_NICSpeed = $NIC.Speed / 1Mb

if($v){
Write-Host "La vitesse de la carte réseau, arrondi à l'entier supérieur, en Mb est :"
Write-Host ([math]::Round($E_NICSpeed)) "Mb"
}

$Exports | Add-Member -MemberType NoteProperty -Name NICSpeed -Value ([math]::Round($E_NICSpeed))

############################################
### SMB
#


if($v){
    Write-Host "`n =-=-=-=-= SMB =-=-=-=-= `n"
    }

$SMBMaps = Get-SmbMapping

#Vérification si le SMB est monté
if($SMBMaps.LocalPath -contains $SMBLetter -and $SMBMaps.RemotePath -contains $SMBPath){
    if($v){
    Write-Host "Le partage existe déjà"
    }
}else{ 
    #Sinon le monte
    if($v){
    Write-Host "Ajout du lecteur réseau $($SMBLetter) allant vers $($SMBPath)"
    }
    
    New-SmbMapping -LocalPath $SMBLetter -RemotePath $SMBPath
}

$Exports | Export-Csv -Path "$SMBPath\$ExportFileName" -Encoding UTF8 -Delimiter ";" -NoTypeInformation -Append

Add-Content "$SMBPath\$ExportFileName" "Presta $IDPresta; Date $Date"
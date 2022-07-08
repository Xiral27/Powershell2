# Script qui fait un export de la configuration contenant : nom du poste, version TPM, Type de CPU, RAM, NIC, DIsk size, OS version
#
# Réalisation par Evan BITIC, Alexis DOUANNES, Théo DUCOIN, Kevin chevreuil
#
#####

$v = $true # Mode verbose
$SMBLetter = "S:" # Lettre du partage réseau
$SMBPath = "\\10.0.0.107\shared" # Chemin du réseau
$InventaireFile = "inventaire.csv" # Fichier d'inventaire

$MigrateFile = "Migrate_status.csv" # Fichier de migration
$IDPresta = "08" # ID du presta


## Script ##########

# Récupération de la date
$Date = Get-Date -format "dd/MM/yyyy à HH:mm"

############################################
### SMB
#

# Récupération de la migration
$MigrateExport = @()

if($v){
    Write-Host "`n =-=-=-=-= SMB =-=-=-=-= `n"
    }

# Récupération des lecteurs déjà mappé
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

# Récupération de l'export du précédent script
$Exports = Import-Csv -Path "$SMBPath\$ExportFileName" -Encoding UTF8 -Delimiter ";"

Foreach($Computer in $Exports){
    
    # Vérification du CPU
    if($Computer.CPU.Substring($Computer.CPU.IndexOf(" i") +2 , 1) -ge 5 -and $Computer.CPU.Substring($Computer.CPU.IndexOf(" i") +4 , 1) -ge 8){
        $CPUCheck = $true
    }else{
        $CPUCheck = $false
    }

    # Vérification des différents prérequis
    if($Computer.TPM -eq "2.0" -and $Computer.RAM -ge 12 -and $Computer.DiskSpace -lt 512 -and $Computer.NICSpeed -ge 1000 -and $CPUCheck){
        $MigrateExport += @([PSCustomObject]@{
        Hostname = $Computer.Hostname # Recuperation du nom de l'OU
        Status = "OK for migrate" # Recuperation du chemin qui doit contenir l'OU
        })
    }else{
        $MigrateExport += @([PSCustomObject]@{
        Hostname = $Computer.Hostname # Recuperation du nom de l'OU
        Status = "Not OK for migrate" # Recuperation du chemin qui doit contenir l'OU
        })
    }
    
    
}

#Migration du fichier
$MigrateExport | Export-CSV -Path "$SMBPath\$MigrateFile" -Encoding UTF8 -Delimiter ";" -NoTypeInformation

Add-Content "$SMBPath\$MigrateFile" "Presta $IDPresta; Date $Date"
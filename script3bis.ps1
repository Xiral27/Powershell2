# Script qui fait un export de la configuration contenant : nom du poste, version TPM, Type de CPU, RAM, NIC, DIsk size, OS version
#
# Réalisation par Evan BITIC, Alexis DOUANNES, Théo DUCOIN, Kevin chevreuil
#
#####

$v = $true # Mode verbose
$SMBLetter = "S:" # Lettrre du partage
$SMBPath = "\\10.0.0.107\shared" # Chemin du partage

$MigrateFile = "Migrate_status.csv" # Fichier des pc à migrer
$MigratePC = "MigratePC.csv" # Fichier des pc migré

$IDPresta = "08" # ID du presta

## Script ##########

# initialisation des compteurs
$DoneCount = 0
$ToDo = 0
$ToChange = 0

# Récupération de la date
$Date = Get-Date -format "dd/MM/yyyy à HH:mm"

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

# Récupération de fichier des PC à migrer
$MigrateImport = Import-Csv -Path "$SMBPath\$MigrateFile" -Encoding UTF8 -Delimiter ";"

# Récupération de fichier des PC migré
$DoneImport = Import-Csv -Path "$SMBPath\$MigratePC" -Encoding UTF8 -Delimiter ";"




Foreach($Computer in $MigrateImport){
    if($DoneImport.Hostname -contains $Computer.Hostname){ # Vérifie si le PC est migré
        $DoneCount++
    }elseif($Computer.Status -like "OK*" -and -not($DoneImport.Hostname -contains $Computer.Hostname)){ # Vérifie si le PC est a migré
        $ToDo++
    }else{ # Donne le nombre de PC à changer
        $ToChange++
    }
}

Write-Host "Le nombre de PC migré est de $DoneCount"
Write-Host "Le nombre de PC qui reste à faire est de $ToDo"
Write-Host "Le nombre de PC à changer est de $ToChange"
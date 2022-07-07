# :: Import module ad 

#Variable

$DomainName = "esgi-src.ads"
$IntervenantsCSVName = "Intervenants.csv"
$OU = "Intervenants"
$GroupName = "Intervenants" # Nom du groupe d'intervenants dans l'AD



$WorkingFolder = Split-Path $MyInvocation.MyCommand.Path -Parent
$Intervenants = Import-CSV -Path ($WorkingFolder + "\" + $IntervenantsCSVName) -Encoding UTF8 -Delimiter ";"

$DN = "OU=$OU,DC=$($DomainName.Split('.')[0]),DC=$($DomainName.Split('.')[1])"

$parentOU =  $DN.Substring($OU.Length+4)

$Password = ConvertTo-SecureString "Pa55W0rd" -AsPlainText -Force 

############################################################################################"
### Date ###
############
# Récupération de la date actuelle
$now = Get-Date


write-host "`n=== Nous sommes le $now, il y a $($Intervenants.Count) intervenants pour cette semaine ==="

# Récupération du jour de la semaine
$day = $now.DayOfWeek.value__

#Date de fin

Write-Host "Préparation des $($Intervenants.Count) comptes"
$currentDay = $now.DayOfWeek.value__

# Détection de la semaine
if($day -ge 5){ # Si semaine prochaine
    for($i = 0;($i + $currentDay) -lt 8;$i++){}

    $EndDay = $now.AddDays($i + 4)
}else{ # Si semaine actuelle
    for($i = 0;($i + $currentDay) -lt 5;$i++){}

    $EndDay = $now.AddDays($i)
}

$EndDay = $EndDay.ToString("MM/dd/yyyy")

Write-Host "La date de fin des intervenants sera le $EndDay"

##################################################################
## Création de l'OU ##
######################



if (Get-ADOrganizationalUnit -Filter "distinguishedName -eq '$DN'") {
  Write-Host "$OU already exists."
} else {
  Write-Host "Création de l'OU : $OU"
  New-ADOrganizationalUnit -Name $OU -Path $parentOU
}

##################################################################
## Groupe ##
############

#Vérification si le groupe "Intervenants" existe

if(-not((Get-ADGroup -Filter * | Select-Object Name).Name -contains $GroupName)){
    Write-Host "Création du groupe $GroupName"

    New-ADGroup -Name $GroupName -GroupScope Global -Path $DN
}else{
    Write-Host "Le groupe $GroupName est déjà créé"
}

##################################################################
## Utilisateurs ##
##################

Foreach($User in $Intervenants){
    $LastName = $User.Nom
    $FirstName = $User.Prenom

    Write-Host "Utilisateur : $LastName $FirstName"

        
    $SAM = ($FirstName.SubString(0,1) + "." + $LastName).ToLower()

    #Vérification si compte existe
    if (Get-ADUser -Filter "sAMAccountName -eq '$SAM'") {#Si SAM existe
        Write-host "débug 1"
        $ADUser = Get-ADUser -Identity $SAM

        #Vérifie si c'est la même personne
        if($ADUser.GivenName -eq $Firstname -and $ADUser.Surname -eq $LastName){ # Si même nom&prenom
            #Réactivation du compte & Expiration
            Enable-ADAccount -Identity $SAM
            Set-ADAccountExpiration -Identity $SAM -DateTime $EndDay
            Write-host "débug 2"
            Continue
        }else{
            Write-host "débug 3"
            $SAM = ($FirstName + "." + "$LastName").ToLower()
        }
    }
    Write-Host "débug 4"
    New-ADUser -GivenName $Firstname -Surname $LastName -Name $SAM -Path $DN -AccountPassword $Password 
    Add-ADGroupMember -Identity $GroupName -Members $SAM
    Set-ADAccountExpiration -Identity $SAM -DateTime $EndDay 
}
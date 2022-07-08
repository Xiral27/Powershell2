# Script qui fait un export de la configuration contenant : nom du poste, version TPM, Type de CPU, RAM, NIC, DIsk size, OS version
#
# R�alisation par Evan BITIC, Alexis DOUANNES, Th�o DUCOIN, Kevin chevreuil
#
#####

#Variable

$DomainName = "esgi-src.ads" 
$IntervenantsCSVName = "Intervenants.csv"
$OU = "Intervenants"
$GroupName = "Intervenants" # Nom du groupe d'intervenants dans l'AD



$WorkingFolder = Split-Path $MyInvocation.MyCommand.Path -Parent
$Intervenants = Import-CSV -Path ($WorkingFolder + "\" + $IntervenantsCSVName) -Encoding UTF8 -Delimiter ";"

$DN = "OU=$OU,DC=$($DomainName.Split('.')[0]),DC=$($DomainName.Split('.')[1])" # G�n�ration du nom de DN enfant

$parentOU =  $DN.Substring($OU.Length+4) # R�cup�ration du DN parents

$Password = ConvertTo-SecureString "Pa55W0rd" -AsPlainText -Force # Cr�ation du mot de passe

############################################################################################"
### Date ###
############
# R�cup�ration de la date actuelle
$now = Get-Date


write-host "`n=== Nous sommes le $now, il y a $($Intervenants.Count) intervenants pour cette semaine ==="

Write-Host "Pr�paration des $($Intervenants.Count) comptes"

# R�cup�ration du jour de la semaine
$currentDay = $now.DayOfWeek.value__

# D�tection de la semaine
if($currentDay -ge 5){ # Si semaine prochaine
    for($i = 0;($i + $currentDay) -lt 8;$i++){}

    $EndDay = $now.AddDays($i + 4)
}else{ # Si semaine actuelle
    for($i = 0;($i + $currentDay) -lt 5;$i++){}

    $EndDay = $now.AddDays($i)
}

$EndDay = $EndDay.ToString("MM/dd/yyyy")

Write-Host "La date de fin des intervenants sera le $EndDay"

##################################################################
## Cr�ation de l'OU ##
######################

if (Get-ADOrganizationalUnit -Filter "distinguishedName -eq '$DN'") {
  Write-Host "$OU already exists."
} else {
  Write-Host "Cr�ation de l'OU : $OU"
  New-ADOrganizationalUnit -Name $OU -Path $parentOU
}

##################################################################
## Groupe ##
############

#V�rification si le groupe "Intervenants" existe

if(-not((Get-ADGroup -Filter * | Select-Object Name).Name -contains $GroupName)){
    Write-Host "Cr�ation du groupe $GroupName"

    New-ADGroup -Name $GroupName -GroupScope Global -Path $DN
}else{
    Write-Host "Le groupe $GroupName est d�j� cr��"
}

##################################################################
## Utilisateurs ##
##################

Foreach($User in $Intervenants){
    $LastName = $User.Nom
    $FirstName = $User.Prenom

    Write-Host "Utilisateur : $LastName $FirstName"

    # G�n�ration du SAM
    $SAM = ($FirstName.SubString(0,1) + "." + $LastName).ToLower()

    #V�rification si compte existe
    if (Get-ADUser -Filter "sAMAccountName -eq '$SAM'") {#Si SAM existe
        $ADUser = Get-ADUser -Identity $SAM

        #V�rifie si c'est la m�me personne
        if($ADUser.GivenName -eq $Firstname -and $ADUser.Surname -eq $LastName){ # Si m�me nom&prenom
            #R�activation du compte & Expiration
            Enable-ADAccount -Identity $SAM
            Set-ADAccountExpiration -Identity $SAM -DateTime $EndDay
            Continue
        }else{
            $SAM = ($FirstName + "." + "$LastName").ToLower()
        }
    }

    # Cr�ation de l'utilisateur
    New-ADUser -GivenName $Firstname -Surname $LastName -Name $SAM -Path $DN -AccountPassword $Password 

    # Ajout de l'utilisateur au group Intervenants
    Add-ADGroupMember -Identity $GroupName -Members $SAM

    # D�finition de la date d'expiration
    Set-ADAccountExpiration -Identity $SAM -DateTime $EndDay 
}
# Script qui fait un export de la configuration contenant : nom du poste, version TPM, Type de CPU, RAM, NIC, DIsk size, OS version

$E_ComputerName = (Get-WMIObject win32_operatingsystem).PSComputerName

# Check TPM

$TPMversion="2.0"
$Query="Select * from win32_tpm"
$NameSpace= "root\cimv2\security\microsofttpm"

$r = Get-WmiObject -Namespace $Namespace -Query $Query

$E_TPM = $r.SpecVersion

### 

$E_CPU = (Get-WmiObject win32_processor).Name



### 

$ram = Get-WMIObject -class win32_ComputerSystem | Select-Object -Expand TotalPhysicalMemory

$ram = (Get-WMIObject win32_operatingsystem).TotalVisibleMemorySize / 1 048 576

## Disk

$E_DiskSpace = (Get-Volume -DriveLetter C).Size / 1Gb

## Os system

$E_OS = (Get-WMIObject win32_operatingsystem).Caption
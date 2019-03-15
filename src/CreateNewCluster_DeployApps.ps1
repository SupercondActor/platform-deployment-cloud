### Create new Service Fabric secure cluster, deploy Manager app and one Service ap

#!!! You must have OpenSSL installed on your computer to split .pfx certificate file into .key and .crt files

### If you see Access Policy exception during cluster creation - clear your PowerShell context:
# Clear-AzureRmContext -Scope CurrentUser

#======================================================================================

# including common scripts
. "$PSScriptRoot\AzureScripts\Common.ps1"

#!!! PARAMETERS: ======================================================================

# Cluster Name - must be globally unique in the region
#  (if not provided will be generated random):
$clusterName = ""

# Cluster location code
$clusterLoc = "southcentralus"

# Number of cluster nodes. Possible values: 1, 3-99
$clusterSize = 3

# Type of VM to use in the cluster
$vmSKU = "Standard_D2_v2"

# Certificate password
#  (if not provided will be generated and written to the ClusterInfo file):
$certPassword = ""

# Password for VM RDP user
#  (if not provided will be generated and written to the ClusterInfo file):
$vmAdminPassword = ""

# End of the parameters section ========================================================

### Don't remove this ID:
[Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.AddUserAgent("pid-a01abf25-0999-4282-97d0-a0a07f8cb1c1")

### Prerequisites verification
try {
    $opensslVersion = openssl version
    Write-Host "Found OpenSSL version $opensslVersion"
}
catch {
    Write-Host "OpenSSL not found. Please make sure you have OpenSSL installed on your system." -ForegroundColor Red
    Write-Host "Press Enter to exit"
    Read-Host
    exit
}

if ([string]::IsNullOrEmpty($clusterName)) {
    $rndCl = -join ((48..57) + (97..122) | Get-Random -Count 10 | % {[char]$_})
    $clusterName = ("sabp" + $rndCl)
}
Write-Host ("Cluster name: " + $clusterName)

# Folder where to save generated certificate and info:
$outputfolder = Join-Path (Join-Path $PSScriptRoot "cluster") $clusterName
New-Item -Path $outputfolder -ItemType Directory -Force | Out-Null

# Where to write info for the new cluster 
$outputFile = Join-Path $outputfolder ("ClusterInfo_" + ($clusterName + ".txt"))

if ([string]::IsNullOrEmpty($certPassword)) {
    $certPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 15 | % {[char]$_})
    ("Certificate password: " + $certPassword) >> $outputFile
}

if ([string]::IsNullOrEmpty($vmAdminPassword)) {
    $vmAdminPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 15 | % {[char]$_})
    ("VMs password: " + $vmAdminPassword) >> $outputFile
}

# variables      
$vaultname = ($clusterName + "-vault")
$subname = "$clusterName.$clusterLoc.cloudapp.azure.com"
$endpoint = ($subname + ":19000")
$certName = ($clusterName + "-cert")
$clusterManagerUrl = ("https://" + $subname + ":19080")
$platformManagerUrl = ("https://" + $subname + "/service-manager")

$clusterManagerAppReplyUrl = ($clusterManagerUrl + "/*")

("Business Platform Manager URL: " + $platformManagerUrl) >> $outputFile

### Connect to AZURE
Write-Host ("Enter your Azure admin credentials in the pop-up window (it might be behind current window) ...") -ForegroundColor Magenta
$subscription = EnsureLoggedIn

$isAvailable = Test-AzureRmDnsAvailability -DomainNameLabel $clusterName -Location $clusterLoc
if ($isAvailable) {
    Write-Host ("The cluster name '" + $clusterName + "' is available in the location '" + $clusterLoc + "'.")
}
else {
    Write-Host ("The cluster name '" + $clusterName + "' is not available in the location '" + $clusterLoc + "'. Please try another name.") -ForegroundColor Yellow
    Write-Host "Press Enter to exit"
    Read-Host
    exit
}

$tenantId = $subscription.TenantId[0].ToString()

$rpUrl = ("https://" + $subname + "/*")

### Create Azure AD Application Registration for authentication
$homeUri = ("https://" + $subname) 
$azureAdAppName = ("SupercondActor-auth-" + $clusterName)   
$appUri = ("https://" + $azureAdAppName)
Write-Host "$(Get-Date -Format T) - Creating Azure AD Application Registration '$azureAdAppName' ..."

$azureAdApp = New-AzureRmADApplication -DisplayName $azureAdAppName -HomePage $homeUri -IdentifierUris $appUri -ReplyUrls $rpUrl
$webAppId = $azureAdApp.ApplicationId.ToString()

Write-Host "$(Get-Date -Format T) - Application authentication configured." -ForegroundColor Green -NoNewline
Write-Host " Creating resource group ..."

### Create resource group
$groupname = EnsureNewResourceGroup $clusterName $clusterLoc

### create vault and certificate
$keyVault = EnsureKeyVault $vaultname $groupname $clusterLoc

$certFilePath = "$outputfolder\$subname.pfx"
$managerPackagePath = Join-Path $PSScriptRoot "ManagerAppPackage"
$servicePackagePath = Join-Path $PSScriptRoot "ServiceAppPackage"

$thumbprint, $certUrl = EnsureSelfSignedCertificate $certName $subname $certPassword $vaultname $certFilePath $managerPackagePath

Write-Host "$(Get-Date -Format T) - Building your cluster. It can take up to 15 minutes, please wait...." -ForegroundColor Yellow

$armParameters = @{
    namePart                = $clusterName;
    rdpPassword             = $vmAdminPassword;
    certificateThumbprint   = $thumbprint;
    sourceVaultResourceId   = $keyVault.ResourceId;
    certificateUrlValue     = $certUrl;
    durabilityLevel         = "Bronze";
    reliabilityLevel        = "Bronze";
    vmInstanceCount         = $clusterSize;
    vmNodeSize              = $vmSKU;
}

# Write-Host $armParameters

New-AzureRmResourceGroupDeployment `
    -ResourceGroupName $groupname `
    -TemplateFile "$PSScriptRoot\cluster.template.json" `
    -Mode Incremental `
    -TemplateParameterObject $armParameters >> $outputFile

### Wait for the cluster to be ready
Write-Host "$(Get-Date -Format T) - Waiting for the cluster to be ready ..." -ForegroundColor Yellow
Start-Sleep -s 240
Write-Host "$(Get-Date -Format T) - Cluster created." -ForegroundColor Green

### Deploy application package
Write-Host "$(Get-Date -Format T) - Deploying Manager application package ..." -ForegroundColor Yellow

$appParams = @{"SupercondActor.Platform.WebManager_AuthClientID" = $webAppId; "SupercondActor.Platform.WebManager_AuthTenantID" = $tenantId}

# Connect to the cluster using a client certificate.
$clusterInfo = Connect-ServiceFabricCluster -ConnectionEndpoint $endpoint -KeepAliveIntervalInSec 10 -X509Credential -ServerCertThumbprint $thumbprint -FindType FindByThumbprint -FindValue $thumbprint -StoreLocation CurrentUser -StoreName My

$managerAppName = "SupercondActor.Platform.WebManagerApp"
$managerAppType = "SupercondActor.Platform.WebManagerAppType"
$managerInstanceName = ("fabric:/" + $managerAppName)

# Copy the application package to the cluster image store.
Copy-ServiceFabricApplicationPackage $managerPackagePath -ApplicationPackagePathInImageStore $managerAppName -ShowProgress

# Register the application type.
Register-ServiceFabricApplicationType -ApplicationPathInImageStore $managerAppName

# Remove the application package to free system resources.
Remove-ServiceFabricApplicationPackage -ApplicationPackagePathInImageStore $managerAppName

# Create the application instance.
New-ServiceFabricApplication -ApplicationName $managerInstanceName -ApplicationTypeName $managerAppType -ApplicationTypeVersion 1.0.0 -ApplicationParameter $appParams

Write-Host "$(Get-Date -Format T) - Manager application package deployed." -ForegroundColor Green
Write-Host "Deploying Service application package ..." -ForegroundColor Yellow

$serviceAppName = "SupercondActor.Platform.BusinessServicesApp"
$serviceAppType = "SupercondActor.Platform.BusinessServicesAppType"
$serviceInstanceName = ("fabric:/" + $serviceAppName + ".01")

$appParams = @{"SupercondActor.Platform.SF.ApiService_AuthClientID" = $webAppId; "SupercondActor.Platform.SF.ApiService_AuthTenantID" = $tenantId}

# Copy the application package to the cluster image store.
Copy-ServiceFabricApplicationPackage $servicePackagePath -ApplicationPackagePathInImageStore $serviceAppName -ShowProgress

# Register the application type.
Register-ServiceFabricApplicationType -ApplicationPathInImageStore $serviceAppName

# Remove the application package to free system resources.
Remove-ServiceFabricApplicationPackage -ApplicationPackagePathInImageStore $serviceAppName

# Create the application instance.
New-ServiceFabricApplication -ApplicationName $serviceInstanceName -ApplicationTypeName $serviceAppType -ApplicationTypeVersion 1.0.0 -ApplicationParameter $appParams

Write-Host "$(Get-Date -Format T) - All done!" -ForegroundColor Green
Write-Host ""
Write-Host "SupercondActor Business Platform Manager URL:"
Write-Host $platformManagerUrl -ForegroundColor Magenta
Write-Host ""
Write-Host "Cluster Manager URL:"
Write-Host $clusterManagerUrl
Write-Host ""

Write-Host "IMPORTANT:" -ForegroundColor Red
Write-Host ("Set Required Permissions for your App Registation '" + $azureAdAppName + "' in Azure Portal!") -ForegroundColor Yellow
Write-Host "Navigate to:" -ForegroundColor Yellow
Write-Host ("https://portal.azure.com/#blade/Microsoft_AAD_IAM/ApplicationBlade/appId/$($azureAdApp.ApplicationId)/objectId/$($azureAdApp.ObjectId)") -ForegroundColor Magenta
Write-Host "Click on 'Settings' > 'Required permissions' > 'Add' > 'Select an API' > 'Windows Azure Active Directory'" -ForegroundColor Yellow
Write-Host "Click 'Select'" -ForegroundColor Yellow
Write-Host "Set checkbox: 'Sign in and read user profile'" -ForegroundColor Yellow
Write-Host "Click 'Select' and 'Done'" -ForegroundColor Yellow
Write-Host ""

Write-Host "Press Enter to exit"
Read-Host

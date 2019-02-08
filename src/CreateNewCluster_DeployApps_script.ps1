### Create new Service Fabric secure cluster, deploy Manager app and one Service ap

#!!! You must have OpenSSL installed on your computer to split .pfx certificate file into .key and .crt files

### If you see Access Policy exception during cluster creation - clear your PowerShell context:
# Clear-AzureRmContext -Scope CurrentUser


#!!! PARAMETERS: ======================================================================

# Cluster Name - must be globally unique in the region
#  (if not provided will be generated random):
$clusterName = ""

# Cluster location code
$clusterLoc = "southcentralus"

# Number of cluster nodes. Possible values: 1, 3-99
$clusterSize = 5

# Type of VM to use in the cluster
$vmSKU = "Standard_D2_v2"

# Active Directory App Registration Name - for authenticatioin
#  (if not provided will be generated from cluster name):
$azureAdAppName = ""

# Certificate password
#  (if not provided will be generated and written to the ClusterInfo file):
$certPassword = ""

# User name and password for VM admin
#  (if not provided will be generated and written to the ClusterInfo file):
$vmAdminUser = "adminuser"
$vmAdminPassword = ""

# End of the parameters section ========================================================


### Variables for common values

# current folder
$path = $PSScriptRoot
if([string]::IsNullOrEmpty($path))
{
    Write-Host "Can't get this script file path." -ForegroundColor Red
    Write-Host "Press Enter to exit"
    Read-Host
    return
}

if([string]::IsNullOrEmpty($clusterName))
{
    $rndCl = -join ((48..57) + (97..122) | Get-Random -Count 10 | % {[char]$_})
    $clusterName = ("sfbp" + $rndCl)
}

# Folder where to save generated certificate and info:
$outputfolder = Join-Path (Join-Path $path "cluster") $clusterName
New-Item -Path $outputfolder -ItemType Directory -Force | Out-Null

# Where to write info for the new cluster 
$outputFile = Join-Path $outputfolder ("ClusterInfo_" + ($clusterName + ".txt"))

if([string]::IsNullOrEmpty($certPassword))
{
    $certPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 15 | % {[char]$_})
    ("Certificate password: " + $certPassword) >> $outputFile
}

if([string]::IsNullOrEmpty($vmAdminPassword))
{
    $vmAdminPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 15 | % {[char]$_})
    ("VMs password: " + $vmAdminPassword) >> $outputFile
}

# derived names
$groupname = ("SupercondActor-" + $clusterName + "-group")
$resourceGroup = Get-AzureRmResourceGroup -Name $groupname -ErrorAction SilentlyContinue      ##!!!!!!!!!!!!!!!!!!!!!!!!!!! Error, should be after login
if($resourceGroup)
{
    $rndClg = -join ((48..57) + (97..122) | Get-Random -Count 10 | % {[char]$_})
    $groupname = ("SupercondActor-sfbp" + $rndClg + "-group")
}
      
$vaultname = ($clusterName + "-vault")
$subname = "$clusterName.$clusterLoc.cloudapp.azure.com"
$endpoint = ($subname + ":19000")

$clusterManagerUrl = ("https://" + $subname + ":19080")
$platformManagerUrl = ("https://" + $subname + "/service-manager")

$certpwd = $certPassword | ConvertTo-SecureString -AsPlainText -Force
$adminpwd = $vmAdminPassword | ConvertTo-SecureString -AsPlainText -Force 


### Prerequisites verification
try
{
    $opensslVersion = openssl version
}
catch
{
    Write-Host "OpenSSL not found. Please make sure you have OpenSSL installed on your system." -ForegroundColor Red
    Write-Host "Press Enter to exit"
    Read-Host
    return
}


### Connect to AZURE
Connect-AzureRmAccount

$isAvailable = Test-AzureRmDnsAvailability -DomainNameLabel $clusterName -Location $clusterLoc
if($isAvailable)
{
    Write-Host ("The cluster name '" + $clusterName + "' is available in the location '" + $clusterLoc + "'.") -ForegroundColor Green
}
else
{
    Write-Host ("The cluster name '" + $clusterName + "' is not available in the location '" + $clusterLoc + "'. Please try another name.") -ForegroundColor Yellow
    Write-Host "Press Enter to exit"
    Read-Host
    return
}

$allSubs = Get-AzureRmSubscription
if($allSubs.Count -eq 1)
{
    $subscription = $allSubs[0]
}
else
{
    Write-Host ("Found " + $allSubs.Count + " available Azure subscriptions.") -ForegroundColor Yellow
    for($i=0; $i -lt $allSubs.Count; $i++)
    {
        Write-Host ($i.ToString() + " - " + $allSubs[$i].Name)
    }
    Write-Host ("Enter a number to select the one you need (Ctrl+C to exit):") -ForegroundColor Yellow
    $nbr = Read-Host
    $subscription = $allSubs[$nbr]
    if($subscription)
    {
        Write-Host ("Selected subscriptioin: '" + $subscription.Name + "'") -ForegroundColor Green
        Select-AzureRmSubscription -SubscriptionId $subscription.Id
    }
    else
    {
        Write-Host ("No subscription selected.") -ForegroundColor Red
        Write-Host "Press Enter to exit"
        Read-Host
        return
    }
}

("Business Platform Manager URL: " + $platformManagerUrl) >> $outputFile

Write-Host ((Get-Date -Format T) + " - Building your cluster. It can take up to 40 minutes, please wait....") -ForegroundColor Yellow

### Create the Service Fabric cluster.
New-AzureRmServiceFabricCluster -Name $clusterName -ResourceGroupName $groupname -Location $clusterLoc `
    -ClusterSize $clusterSize -VmUserName $vmAdminUser -VmPassword $adminpwd -CertificateSubjectName $subname `
    -CertificatePassword $certpwd -CertificateOutputFolder $outputfolder `
    -OS WindowsServer2016DatacenterwithContainers -VmSku $vmSKU -KeyVaultName $vaultname >> $outputFile

Write-Host ((Get-Date -Format T) + " - Nodes created.") -ForegroundColor Green

### Replace Load Balancer app rules with rules required for SupercondActor Manager app
Write-Host "Setting Load Balancer rules..." -ForegroundColor Yellow

$resource = Get-AzureRmResource | Where {$_.ResourceGroupName -eq $groupname -and $_.ResourceType -eq "Microsoft.Network/loadBalancers"}
if(-Not ($resource))
{
    Write-Host "Error looking for a Load Balancer" -ForegroundColor Red
    Write-Host "Press Enter to exit"
    Read-Host
    return
}

$slb = Get-AzureRmLoadBalancer -Name $resource.Name -ResourceGroupName $groupname

#delete existing app Load Balancer rules
$apprules = [System.Collections.ArrayList]@()
foreach($rule in $slb.LoadBalancingRules)
{
    if($rule.Name.StartsWith("App"))
    {
        $arrayID = $apprules.Add($rule)
    }
}

foreach($rule in $apprules)
{
    $probeName = Split-Path -Path $rule.Probe.Id -Leaf
    Write-Host ("Removing existing rule '" + $rule.Name + "' and probe '" + $probeName + "' for port " + $rule.BackendPort)
    $tmplbr = Remove-AzureRmLoadBalancerRuleConfig -Name $rule.Name -LoadBalancer $slb
    $tmplbp = Remove-AzureRmLoadBalancerProbeConfig -Name $probeName -LoadBalancer $slb
}

# create new Load Balancer rules
# (you probably want to remove Traefik port 8080 in production environment)
$ports = 80,443,8080 

foreach ($port in $ports)
{
    $probename = ("SaAppPortProbe" + $port)
    $rulename = ("SaAppPortLBRule" + $port)

    Write-Host ("Adding rule '" + $rulename + "' for port " + $port)

    # Add a new probe configuration to the load balancer
    $slb | Add-AzureRmLoadBalancerProbeConfig -Name $probename -Protocol Tcp -Port $port -IntervalInSeconds 15 -ProbeCount 2 | Out-Null

    # Add rule configuration to the load balancer
    $probe = Get-AzureRmLoadBalancerProbeConfig -Name $probename -LoadBalancer $slb
    $slb | Add-AzureRmLoadBalancerRuleConfig -Name $rulename -BackendAddressPool $slb.BackendAddressPools[0] -FrontendIpConfiguration $slb.FrontendIpConfigurations[0] -Probe $probe -Protocol Tcp -FrontendPort $port -BackendPort $port | Out-Null
}

Write-Host "Configuring Load Balancer. It can take up to 20 minutes, please wait...." -ForegroundColor Yellow
$slb | Set-AzureRmLoadBalancer | Out-Null

Write-Host ((Get-Date -Format T) + " - Load Balancer configured.") -ForegroundColor Green

### Replace Network Security Group app rules with rules required for SupercondActor Manager app
Write-Host "Setting Network Security Group rules..." -ForegroundColor Yellow

# Get the Network Security Group resource
$nsgResource = Get-AzureRmResource | Where {$_.ResourceGroupName -eq $groupname -and $_.ResourceType -eq "Microsoft.Network/networkSecurityGroups"}
$nsg = Get-AzureRmNetworkSecurityGroup -Name $nsgResource.Name -ResourceGroupName $groupname

$nsgApprules = [System.Collections.ArrayList]@()
foreach($rule in $nsg.SecurityRules)
{
    if($rule.Name.StartsWith("allowApp"))
    {
        $arrayID = $nsgApprules.Add($rule)
    }
}

foreach($rule in $nsgApprules)
{
    $tmpng = Remove-AzureRmNetworkSecurityRuleConfig -Name $rule.Name -NetworkSecurityGroup $nsg
}
$nsg | Set-AzureRmNetworkSecurityGroup | Out-Null
Write-Host ((Get-Date -Format T) + " - Deleted default Network Security Group rules. Setting rules required for SupercondActor Manager app...")

$ports = "80","443","8080"
$priority = 1000

foreach ($port in $ports)
{
    $rulename = ("allowSaAppPort" + $port)
    $priority = $priority + 10

    $nsg | Add-AzureRmNetworkSecurityRuleConfig -Name $rulename -Access Allow `
	    -Protocol Tcp -Direction Inbound -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
	    -Priority $priority -DestinationPortRange "$port" | Out-Null
}
$nsg | Set-AzureRmNetworkSecurityGroup | Out-Null

Write-Host ((Get-Date -Format T) + " - Network Security Group configured.") -ForegroundColor Green

### Import generated certificate to be able to use Cluster Manager in a browser (use Chrome)
Write-Host "Processing cluster certificate..." -ForegroundColor Yellow

$files = @(Get-ChildItem $outputfolder *.pfx -File | select -ExpandProperty FullName)
$pfx = $files[0]

Import-PfxCertificate -Exportable -CertStoreLocation Cert:\CurrentUser\My -FilePath $pfx -Password $certpwd

### Split .pfx certificate file into .key and .crt files, put them into the Traefik service definition inside the Manager App package
$managerPackagePath = Join-Path $path "ManagerPackage"
$servicePackagePath = Join-Path $path "ServicePackage"

$keyFile = Join-Path $managerPackagePath "TraefikPkg\Code\certs\cluster.key"
openssl pkcs12 -in $pfx -nocerts -nodes -out $keyFile -passin pass:$certPassword

$crtFile = Join-Path $path "ManagerPackage\TraefikPkg\Code\certs\cluster.crt"
openssl pkcs12 -in $pfx -clcerts -nokeys -out $crtFile -passin pass:$certPassword

# get certificate thumbprint
$certPrint = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$certPrint.Import($crtFile)   
$thumbprint = $certPrint.Thumbprint

Write-Host ((Get-Date -Format T) + " - Application package updated with the cluster certificate.") -ForegroundColor Green


### Create Azure AD Application Registration for authentication
Write-Host "Creating Azure AD Application Registration for authentication..." -ForegroundColor Yellow

$homeUri = ("https://" + $subname)
$replyUrls = $homeUri, ($homeUri + "/*")

if([string]::IsNullOrEmpty($azureAdAppName))
{
    $azureAdAppName = ("SupercondActor-auth-" + $clusterName)
}
$appUri = ("https://" + $azureAdAppName)

$azureAdApp = Get-AzureRmADApplication -DisplayName $azureAdAppName
$newAzureAdApp = $false
if($azureAdApp)
{

     Write-Host ("Found existing Application Registration for " + $azureAdApp.DisplayName + ". Updating Reply URLs...")
     foreach($rpUrl in $replyUrls)
     {
        if($azureAdApp.ReplyUrls.Contains($rpUrl))
        {
             Write-Host ("Url " + $rpUrl + " exists.")
        }
        else
        {
             Write-Host ("Adding url " + $rpUrl + " ...")
             $azureAdApp.ReplyUrls.Add($rpUrl);
             $azureAdApp | Update-AzureRmADApplication -ReplyUrl $azureAdApp.ReplyUrls | Out-Null
        }
     }
}
else
{   
    Write-Host ("Creating Application Registration " + $azureAdApp.DisplayName + " ...")
    $azureAdApp = New-AzureRmADApplication -DisplayName $azureAdAppName -HomePage $homeUri -IdentifierUris $appUri -ReplyUrls $replyUrls
    $newAzureAdApp = $true
}

Write-Host ("Application Name: " + $azureAdAppName)
Write-Host ("Application Id: " + $azureAdApp.ApplicationId.Guid)
Write-Host ("Tenant Id: " + $subscription.TenantId)

$appParams = @{"SupercondActor.Platform.WebManager_AuthClientID" = $azureAdApp.ApplicationId.Guid.ToString(); "SupercondActor.Platform.WebManager_AuthTenantID" = $subscription.TenantId}

Write-Host ((Get-Date -Format T) + " - Azure AD Application Registration complete.") -ForegroundColor Green


### Deploy application package
Write-Host "Deploying Manager application package..." -ForegroundColor Yellow

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

Write-Host ((Get-Date -Format T) + " - Manager application package deployed.") -ForegroundColor Green
Write-Host "Deploying Service application package..." -ForegroundColor Yellow

$serviceAppName = "SupercondActor.Platform.BusinessServicesApp"
$serviceAppType = "SupercondActor.Platform.BusinessServicesAppType"
$serviceInstanceName = ("fabric:/" + $serviceAppName + ".01")

$appParams = @{"SupercondActor.Platform.SF.ApiService_AuthClientID" = $azureAdApp.ApplicationId.Guid.ToString(); "SupercondActor.Platform.SF.ApiService_AuthTenantID" = $subscription.TenantId}

# Copy the application package to the cluster image store.
Copy-ServiceFabricApplicationPackage $servicePackagePath -ApplicationPackagePathInImageStore $serviceAppName -ShowProgress

# Register the application type.
Register-ServiceFabricApplicationType -ApplicationPathInImageStore $serviceAppName

# Remove the application package to free system resources.
Remove-ServiceFabricApplicationPackage -ApplicationPackagePathInImageStore $serviceAppName

# Create the application instance.
New-ServiceFabricApplication -ApplicationName $serviceInstanceName -ApplicationTypeName $serviceAppType -ApplicationTypeVersion 1.0.0 -ApplicationParameter $appParams


Write-Host ((Get-Date -Format T) + " - All done!") -ForegroundColor Green
Write-Host ""
Write-Host "Business Platform Manager URL:"
Write-Host $platformManagerUrl -ForegroundColor Magenta
Write-Host ""
Write-Host ("Cluster Manager URL (open in Chrome and select certificate '$subname'):")
Write-Host $clusterManagerUrl
Write-Host ""

if($newAzureAdApp)
{
    Write-Host "IMPORTANT:" -ForegroundColor Red
    Write-Host ("Set Required Permissions for your App Registation '" + $azureAdAppName + "' in Azure Portal!") -ForegroundColor Yellow
    Write-Host "Navigate to:" -ForegroundColor Yellow
    Write-Host ("https://portal.azure.com/#blade/Microsoft_AAD_IAM/ApplicationBlade/appId/$($azureAdApp.ApplicationId)/objectId/$($azureAdApp.ObjectId)") -ForegroundColor Magenta
    Write-Host "Click on 'Settings' > 'Required permissions' > 'Add' > 'Select an API' > 'Windows Azure Active Directory'" -ForegroundColor Yellow
    Write-Host "Click 'Select'" -ForegroundColor Yellow
    Write-Host "Set checkbox: 'Sign in and read user profile'" -ForegroundColor Yellow
    Write-Host "Click 'Select' and 'Done'" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Press Enter to exit"
Read-Host

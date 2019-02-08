### Configure existing Service Fabric cluster, deploy Manager app and one Service app

#!!! You must have OpenSSL installed on your computer to run this script


#!!! REQUIRED PARAMETERS: ======================================================================

# PROVIDE CLUSTER NAME
$clusterName = ""

# PROVIDE RESOURCE GROUP NAME
$groupName = ""

# PROVIDE PATH TO THE EXISTING CLUSTER'S CERTIFICATE PFX FILE
$certPfxFile = ""

# PROVIDE CERTIFICATE PASSWORD
$certPassword = ""

# End of the parameters section ========================================================


# current folder
$path = $PSScriptRoot

# Prerequisites verification
if([string]::IsNullOrEmpty($clusterName)){
	Write-Host "Provide Cluster Name in the variable '`$clusterName'" -ForegroundColor Red
    Write-Host "Press Enter to exit"
    Read-Host
	return
}

if([string]::IsNullOrEmpty($groupName)){
	Write-Host "Provide Resource Group Name in the variable `$groupName" -ForegroundColor Red
    Write-Host "Press Enter to exit"
    Read-Host
	return
}

if([string]::IsNullOrEmpty($certPfxFile)){
	Write-Host "Provide Cluster Certificate file path in the variable `$certPfxFile" -ForegroundColor Red
    Write-Host "Press Enter to exit"
    Read-Host
	return
}

if(!(Test-Path $certPfxFile -PathType Leaf)){
	Write-Host "Certificate file $certPfxFile not found" -ForegroundColor Red
    Write-Host "Press Enter to exit"
    Read-Host
	return
}

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

Write-Host ((Get-Date -Format T) + " - Configuring your cluster. It can take several minutes, please wait...") -ForegroundColor Yellow

### Get the Service Fabric cluster.
$cluster = Get-AzureRmServiceFabricCluster -Name $clusterName -ResourceGroupName $groupName
if(-Not ($cluster))
{
    Write-Host "Cluster not found. Verify group name and cluster name provided in the parameters." -ForegroundColor Red
    Write-Host "Press Enter to exit"
    Read-Host
    return
}
$subname = $cluster.ManagementEndpoint.Substring(8, $cluster.ManagementEndpoint.Length - 14)

$resource = Get-AzureRmResource | Where {$_.ResourceGroupName -eq $groupName -and $_.ResourceType -eq "Microsoft.Network/loadBalancers"}
if(-Not ($resource))
{
    Write-Host "Error looking for a Load Balancer" -ForegroundColor Red
    Write-Host "Press Enter to exit"
    Read-Host
    return
}

Write-Host ((Get-Date -Format T) + " - Cluster located.") -ForegroundColor Green

### Replace Load Balancer app rules with rules required for SupercondActor Manager app
Write-Host "Setting Load Balancer rules..." -ForegroundColor Yellow

$slb = Get-AzureRmLoadBalancer -Name $resource.Name -ResourceGroupName $groupName

# Configure ports (you probably want to remove Traefik port 8080 in production environment)
$ports = 80,443,8080 
#delete existing app Load Balancer rules
$apprules = [System.Collections.ArrayList]@()
foreach($rule in $slb.LoadBalancingRules)
{
    if($ports.Contains($rule.BackendPort))
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



### Import generated certificate to be able to use Cluster Manager in a browser (use Chrome)
Write-Host "Processing cluster certificate..." -ForegroundColor Yellow


$certObj = Import-PfxCertificate -Exportable -CertStoreLocation Cert:\CurrentUser\My -FilePath $certPfxFile -Password $certpwd

### Split .pfx certificate file into .key and .crt files, put them into the Traefik service definition inside the Manager App package
$managerPackagePath = Join-Path $path "ManagerPackage"
$servicePackagePath = Join-Path $path "ServicePackage"

$keyFile = Join-Path $managerPackagePath "TraefikPkg\Code\certs\cluster.key"
openssl pkcs12 -in $certPfxFile -nocerts -nodes -out $keyFile -passin pass:$certPassword

$crtFile = Join-Path $path "ManagerPackage\TraefikPkg\Code\certs\cluster.crt"
openssl pkcs12 -in $certPfxFile -clcerts -nokeys -out $crtFile -passin pass: $certPassword

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

$endpoint = ($subname + ":19000")

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

# Copy the application package to the cluster image store.
Copy-ServiceFabricApplicationPackage $servicePackagePath -ApplicationPackagePathInImageStore $serviceAppName -ShowProgress

# Register the application type.
Register-ServiceFabricApplicationType -ApplicationPathInImageStore $serviceAppName

# Remove the application package to free system resources.
Remove-ServiceFabricApplicationPackage -ApplicationPackagePathInImageStore $serviceAppName

# Create the application instance.
New-ServiceFabricApplication -ApplicationName $serviceInstanceName -ApplicationTypeName $serviceAppType -ApplicationTypeVersion 1.0.0


Write-Host ((Get-Date -Format T) + " - All done!") -ForegroundColor Green
Write-Host ""
Write-Host "Business Platform Manager URL:"
Write-Host ("https://" + $subname + "/service-manager") -ForegroundColor Magenta
Write-Host ""
Write-Host ("Cluster Manager URL (open in Chrome and select certificate '$subname'):")
Write-Host ("https://" + $subname + ":19080")
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

Write-Host "If you have a Network Security Group in the cluster setup, you might need to configure access to ports 80, 443, 8080, and 32006" -ForegroundColor Yellow

Write-Host ""
Write-Host "Press Enter to exit"
Read-Host

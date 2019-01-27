$ErrorActionPreference = 'Stop'

function EnsureLoggedIn()
{
    ### Connect to AZURE
    Write-Host ("Enter your Azure admin credentials in the popup window...") -ForegroundColor Magenta
    Connect-AzureRmAccount
    ConnectAzureAD

    $allSubs = Get-AzureRmSubscription
    if($allSubs.Count -eq 1)
    {
        $sub = $allSubs[0]
        Write-Host ("$(Get-Date -Format T) - Exists subscriptioin: '" + $sub.Name + "'") -ForegroundColor Green
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
        $sub = $allSubs[$nbr]
        if($sub)
        {
            Write-Host ("$(Get-Date -Format T) - Selected subscriptioin: '" + $sub.Name + "'") -ForegroundColor Green
            Select-AzureRmSubscription -SubscriptionId $sub.Id
        }
        else
        {
            Write-Host ("No subscription selected.") -ForegroundColor Red
            Write-Host "Press Enter to exit"
            Read-Host
            exit
        }
    }
    $sub
}

function EnsureNewResourceGroup([string]$clusterName, [string]$Location)
{
    $Name = ("SupercondActor-sabp" + $clusterName + "-group")
    $resourceGroup = Get-AzureRmResourceGroup -Name $Name -Location $Location -ErrorAction Ignore
    if($resourceGroup -ne $null)
    {
        $rndClg = -join ((48..57) + (97..122) | Get-Random -Count 10 | % {[char]$_})
        $Name = ("SupercondActor-sabp" + $rndClg + "-group")
        Write-Host "$(Get-Date -Format T) - Resource group already exists, using another name '$Name'"
    }
    $resourceGroup = New-AzureRmResourceGroup -Name $Name -Location $Location
    Write-Host "$(Get-Date -Format T) - Resource group '$Name' created." -ForegroundColor Green
    $Name
}

function EnsureKeyVault([string]$Name, [string]$ResourceGroupName, [string]$Location)
{
    # KV must be enabled for deployment (last parameter)
    Write-Host ((Get-Date -Format T) + " - Creating Key Vault '$Name'...")
    $keyVault = Get-AzureRmKeyVault -VaultName $Name -ErrorAction Ignore
    if($keyVault -eq $null)
    {
        $keyVault = New-AzureRmKeyVault -VaultName $Name -ResourceGroupName $ResourceGroupName -Location $Location -EnabledForDeployment
        Write-Host ((Get-Date -Format T) + " - Key Vault Created and enabled for deployment.") -ForegroundColor Green
    }
    else
    {
        Write-Host "Key Vault already exists." -ForegroundColor Green
    }

    $keyVault
}

function EnsureSelfSignedCertificate([string]$certName, [string]$DnsName, [string]$certPassword, $KeyVaultName, [string]$filePath)
{   
    $securePassword = ConvertTo-SecureString $certPassword -AsPlainText -Force
    $thumbprint = (New-SelfSignedCertificate -DnsName $DnsName -CertStoreLocation Cert:\CurrentUser\My -KeySpec KeyExchange).Thumbprint
    
    $certContent = (Get-ChildItem -Path cert:\CurrentUser\My\$thumbprint)
    $t = Export-PfxCertificate -Cert $certContent -FilePath $filePath -Password $securePassword
    Write-Host "$(Get-Date -Format T) - Exported certificate to $filePath"

    $kvCert = Import-AzureKeyVaultCertificate -VaultName $KeyVaultName -Name $certName -FilePath $filePath -Password $securePassword
    Write-Host ("$(Get-Date -Format T) - Imported certificate to key vault: " + $kvCert.SecretId) -ForegroundColor Green
    
    $thumbprint
    $kvCert.SecretId
}

function RegisterAADApplication([string]$clusterName, [string]$subname, [string]$azureAdAppName){
    
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

    $azureAdAppID = $azureAdApp.ApplicationId.Guid.ToString()
    Write-Host ("Application Name: " + $azureAdAppName)
    Write-Host ("Application Id: " + $azureAdAppID)
    Write-Host ("Tenant Id: " + $subscription.TenantId)

    Write-Host ((Get-Date -Format T) + " - Azure AD Application Registration complete.") -ForegroundColor Green

    $azureAdAppName
    $azureAdAppID
    $newAzureAdApp
}

function Connect-SecureCluster([string]$ClusterName, [string]$Thumbprint)
{
    $Endpoint = "$ClusterName.westeurope.cloudapp.azure.com:19000"

    Write-Host "connecting to cluster $Endpoint using cert thumbprint $Thumbprint..."
    
    Connect-ServiceFabricCluster -ConnectionEndpoint $Endpoint `
        -X509Credential `
        -ServerCertThumbprint $Thumbprint `
        -FindType FindByThumbprint -FindValue $Thumbprint `
        -StoreLocation CurrentUser -StoreName My
}

function Unregister-ApplicationTypeCompletely([string]$ApplicationTypeName)
{
    Write-Host "checking if application type $ApplicationTypeName is present.."
    $type = Get-ServiceFabricApplicationType -ApplicationTypeName $ApplicationTypeName
    if($type -eq $null) {
        Write-Host "  application is not in the cluster"
    } else {
        $runningApps = Get-ServiceFabricApplication -ApplicationTypeName $ApplicationTypeName
        foreach($app in $runningApps) {
            $uri = $app.ApplicationName.AbsoluteUri
            Write-Host "    unregistering '$uri'..."

            $t = Remove-ServiceFabricApplication -ApplicationName $uri -ForceRemove -Verbose -Force
        }

        Write-Host "  unregistering type..."
        $t =Unregister-ServiceFabricApplicationType `
            -ApplicationTypeName $ApplicationTypeName -ApplicationTypeVersion $type.ApplicationTypeVersion `
            -Force -Confirm

    }
}

function ConnectAzureAD(){
    $currentAzureContext = Get-AzureRmContext
    $tenantId = $currentAzureContext.Tenant.Id
    $accountId = $currentAzureContext.Account.Id
    Connect-AzureAD -TenantId $tenantId -AccountId $accountId
}
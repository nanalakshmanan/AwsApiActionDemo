[CmdletBinding()]
param(
)

. "./Settings.ps1"

$AllStacks = @($EmailLambdaStack, $LinuxInstanceStack, $WindowsInstanceStack)
function Get-Parameter
{
	param(
		[Parameter(Position=0)]
		[string]
		$Key,

		[Parameter(Position=1)]
		[string]
		$Value
	)
	$Param = New-Object Amazon.CloudFormation.Model.Parameter
	$Param.ParameterKey = $Key
	$Param.ParameterValue = $Value
	
	return $Param
}

function Wait-Stack
{
	param(
		[string]
		$StackName
	)
	$Status = (Get-CFNStack -StackName $StackName).StackStatus
	
	while ($Status -ne 'CREATE_COMPLETE'){
		Write-Verbose "Waiting for stack creation to complete  $StackName"
		Start-Sleep -Seconds 5
		$Status = (Get-CFNStack -StackName $StackName).StackStatus
	}
}

# create the cloud formation stacks
$contents = Get-Content ./CloudFormationTemplates/SendMailLambda.yml -Raw
$Role = Get-Parameter 'RoleName' $RoleName
$LambdaFunction = Get-Parameter 'FunctionName' $LambdaFunctionName

New-CFNStack -StackName $EmailLambdaStack -TemplateBody $contents -Parameter @($Role, $LambdaFunction) -Capability CAPABILITY_NAMED_IAM

$InstanceProfile = Get-Parameter 'InstanceProfileName' $InstanceProfileName
$KeyPair = Get-Parameter 'KeyPairName' $KeyPairName
$AmiId = Get-Parameter 'AmiId' $LinuxAmiId
$Vpc = Get-Parameter 'VpcId' $VpcId

$contents = Get-Content ./CloudFormationTemplates/LinuxInstances.yml -Raw 
New-CFNStack -StackName $LinuxInstanceStack -TemplateBody $contents -Parameter @($InstanceProfile, $KeyPair, $AmiId, $Vpc)

$InstanceProfile = Get-Parameter 'InstanceProfileName' $InstanceProfileName
$KeyPair = Get-Parameter 'KeyPairName' $KeyPairName
$AmiId = Get-Parameter 'AmiId' $WindowsAmidId
$Vpc = Get-Parameter 'VpcId' $VpcId

$contents = Get-Content ./CloudFormationTemplates/WindowsInstances.yml -Raw 
New-CFNStack -StackName $WindowsInstanceStack -TemplateBody $contents -Parameter @($InstanceProfile, $KeyPair, $AmiId, $Vpc)

# wait for the stack creation to complete
$AllStacks | %{
	Wait-Stack -StackName $_
}

$contents = Get-Content ../Nana-StartEC2Instance.yml -Raw
New-SSMDocument -Content $contents -DocumentType Automation -Name $StartEC2InstanceDoc -DocumentFormat YAML -TargetType '/AWS::EC2::Instance'

$contents = Get-Content ../Nana-CheckCloudTrailLoggingStatus.yml -Raw
New-SSMDocument -Content $contents -DocumentType Automation -Name $CheckCTLoggingStatusDoc -DocumentFormat YAML -TargetType '/AWS::CloudTrail::Trail'

$contents = Get-Content ../Nana-AuditCloudTrailLogging.yml -Raw
New-SSMDocument -Content $contents -DocumentType Automation -Name $AuditCTLoggingDoc -DocumentFormat YAML -TargetType '/AWS::CloudTrail::Trail'

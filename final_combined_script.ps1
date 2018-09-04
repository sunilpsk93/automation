get-date
$input_path = "E:\Automation\output\reservation_input.csv"
$scope_export_path = "E:\Automation\output\scopereport.csv"
$scope_option_export_path = "E:\Automation\output\scopeoptionreport.csv"
$reservation_export_path = "E:\Automation\output\reservation.csv"
$comp = "10.237.36.155" #server_to_create_new_Scopes.

$server = Import-Csv $input_path

$d = get-date -f 'dd_MM_yy_ss'
$scopereport = @()
$scopeoptionreport =@()

Write-Host "EXPORTING OPTIONS & RESERVATIONS FROM GIVEN SCOPE" -ForegroundColor Green

foreach($ser1 in $server ){
$ser = $ser1.server
$scopeid = $ser1.scope

Write-Host $scopeid -ForegroundColor Blue

if(($ser.Length -gt 0) -and ($scopeid.Length -gt 0)){

Write-Host $scopeid -ForegroundColor Green  

$inp = @() 
$inp += Get-DhcpServerv4Scope -ComputerName $ser -ScopeId $scopeid
$objectscope = $inp | select @{n="Server";e={$ser}},@{n="Scopeid";e={$scopeid}},@{n="Scope Name";e={$_.name}},@{n="Subnet";e={$_.SubnetMask}},@{n="state";e={$_.State}},@{n="StartRange";e={$_.StartRange}},@{n="EndRange";e={$_.EndRange}}
$scopereport += $objectscope 

$scope = @()
    $scope += Get-DhcpServerv4OptionValue -ComputerName $ser -ScopeId $scopeid -All
    #$res += Get-DhcpServerv4Reservation -ComputerName $ser -ScopeId $server
    
   
    $object = $scope|select @{n="Server";e={$ser}},@{n="Scopeid";e={$scopeid}},@{n="Definition Name";e={$_.name}},@{n="Optionid";e={$_.optionid}},@{n="Value";e={$_.value}}

$scopeoptionreport += $object
}

}


$scopereport | Export-Csv -Path $scope_export_path -NoTypeInformation 

$scopeoptionreport | Export-Csv -Path $scope_option_export_path -NoTypeInformation 


########################## Export Reservation ############################

$res_details = @()

foreach($res in $server){
#$res.Server = 'sg-sin-ndhcp01.ap.elcompanies.net'

#Get-DhcpServerv4Reservation -ComputerName sg-sin-ndhcp01.ap.elcompanies.net -ScopeId $res.scope 

$res_details += Get-DhcpServerv4Reservation -ComputerName $res.Server -ScopeId $res.Scope
$object_res = $res_details | select @{n="Server";e={$res.Server}},@{n="Scopeid";e={$_.Scopeid}},@{n="reservation_name";e={$_.name}},@{n="IP";e={$_.IPAddress}},@{n="ClientId";e={$_.ClientId}},@{n="Description";e={$_.Description}}



}



$object_res = $object_res | Export-Csv $reservation_export_path -NoTypeInformation



################# CREATION PART #################

Write-Host "SCOPE CREATION STARTS FROM HERE" -ForegroundColor Green


################################## Scope Creation ##########################

$details = Import-Csv -Path $scope_export_path

foreach($tempdetails in $details){

$scopename = $tempdetails.'Scope Name'
$srange = $tempdetails.StartRange
$erange = $tempdetails.EndRange
$submask = $tempdetails.Subnet
$state = $tempdetails.state

$a = Add-DhcpServerv4Scope -Name $scopename -StartRange $srange -EndRange $erange -SubnetMask $submask -State $state -ComputerName $comp
#Write-Host $a

}


##################################### Set Option value #####################

$option_details = Import-Csv -Path $scope_option_export_path

foreach($x in $option_details){

if($x.Value -match ' '){
$cou = $x.Value.Split(' ')
$temp=''
foreach($cou1 in $cou){


$temp += '"'+$cou1+'"'+","



}
$va = $temp.Substring(0,($temp.Length - 1))
#$va

$sid = $x.Scopeid
$oid = $x.Optionid
#$serv = $x.Server
$a = "Set-DhcpServerv4OptionValue -ScopeId $sid -OptionId $oid -Value $va -ComputerName $comp -Force"
Invoke-Expression $a 
#Start-Sleep 10
$final1+= $temp
}
else{

$sid = $x.Scopeid
$oid = $x.Optionid
$vid = $x.Value
$serv = $x.Server
Set-DhcpServerv4OptionValue -ScopeId $sid -OptionId $oid -Value $vid -ComputerName $comp -Force


}


}

############################ Reservation ######################################


$reservartion = Import-Csv $reservation_export_path
foreach($y in $reservartion){
#$serve = $y.Server
Add-DhcpServerv4Reservation -ComputerName $comp -ScopeId $y.Scopeid -IPAddress $y.IP -ClientId $y.ClientId -Name $y.reservation_name -Description $y.Description


}


get-date

Write-Host "SCRIPT ENDS HERE"
##########################


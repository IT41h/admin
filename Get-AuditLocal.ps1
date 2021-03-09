# this script does not any harm to your computer.

# "https://raw.githubusercontent.com/IT41h/admin/main/Get-AuditLocal.ps1"| %{iex ((New-Object System.Net.WebClient).DownloadString($_))}

$RemoteBlock = {

function Get-RamCPUconfig
{

$size = (((Get-WmiObject -Class Win32_PhysicalMemory).capacity |Measure-Object -sum ).sum / 1GB).Tostring()

# this needs to be adjusted for old rusty machines with PS 2.0: 
$cores = (Get-WmiObject -Class Win32_Processor).NumberOfLogicalProcessors
$sockets=$cores.count
"* RAM Size: $size GB `t CPU Cores: " + $cores + "`t CPU sockets: " + $sockets 

} #get-ramcpuconfig
		
Function CheckAllAutoNotRunningSvc
    {      
Get-wmiobject win32_service -Filter 'startmode = "auto" AND state != "running"' | select Name,Displayname,State,ExitCode,PathName | ft -auto
	} #CheckAllAutoNotRunningSvc

Function CheckDiskSpace
{
get-wmiobject Win32_LogicalDisk -filter "drivetype=3" | select Name, VolumeName,@{Name="Free (%)";Expression={"{0,6:P0}" -f(($_.freespace/1gb) / ($_.size/1gb))}}, Description, @{Label="TotalSize";Expression={"{0:n0} MB" -f ($_.Size/1mb)}}, @{Label="FreeSpace";Expression={"{0:n0} MB" -f ($_.FreeSpace/1mb)}} | FT -auto 

}

Function CheckCPUload
{
$comptype = (gwmi win32_operatingsystem).caption + " @ " + (gwmi Win32_ComputerSystem).model 

[string]$load ="* "+$comptype+" | CPU load: "+ (Get-WmiObject -class win32_processor | Measure-Object -property LoadPercentage -Average | select -expandproperty average).ToString() + " %"
$load
}
Function CheckUpTime
{
$os = gwmi win32_operatingsystem


        $timeZone=Get-WmiObject -Class win32_timezone 
        $localTime = Get-WmiObject -Class win32_localtime 
     

$servertime = "* Local time: " + (Get-Date -Day $localTime.Day -Month $localTime.Month).ToString() + " | " + ($timezone.caption).Tostring() + ""
$serverIP = "* Primary IP address: " + ((Gwmi Win32_NetworkAdapterConfiguration | where {$_.DefaultIPGateway -ne $null}).IPAddress | select -first 1)
$BootTime = $OS.ConvertToDateTime($OS.LastBootUpTime)  
$Uptime = ($OS.ConvertToDateTime($OS.LocalDateTime) - $boottime).ToString() 
$lastboot = "* Last reboot: " + ($boottime).Tostring() + " local time | Uptime: " + $UpTime 
$lastboot
$servertime
$serverip

}

function Get-PageFileMemory 
{

$pf = get-wmiobject -class "Win32_PageFileUsage" -namespace "root\CIMV2" # nactu si detaily o pagefile
$pfused = ($pf.currentusage / ($pf.allocatedbasesize / 100)).ToString("00.00")  # vypocitam procenta

$pf | Add-Member -type NoteProperty -name PFUsedPct -Value $pfused #pridam vlastnost

$memused = Get-WmiObject win32_operatingsystem |
                  Foreach {"{0:N2}" -f ((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)*100)/ $_.TotalVisibleMemorySize)}
				  
$pf | Add-Member -type NoteProperty -name RAMUsedPct -Value $memused #pridam vlastnost

$pf | fl Caption, AllocatedBaseSize, CurrentUsage, PeakUsage, PFUsedPct, RAMUsedPct # zobrazim to co chci videt
}

CheckCPUload
CheckUpTime 
Get-RamCPUconfig
Get-PageFileMemory
 
"* Local Drives utilizaton: ";CheckDiskSpace
"* Stopped auto-starting Services: ";CheckAllAutoNotRunningSvc
} #end of remote block

$computer = $env:computername

$datum = (Get-Date).ToString() 

$zdravicko = &$RemoteBlock

$zdravicko




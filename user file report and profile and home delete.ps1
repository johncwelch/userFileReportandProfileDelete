Set-ExecutionPolicy RemoteSigned

#VB Code for name entry
Add-Type -AssemblyName Microsoft.VisualBasic

##get user name
$userName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the user name whose profile you want to delete", "Get User Name")

#note that if we had a massive domain, this would be unweildy. It pulls the user name domain and SID info
#if it is a local account that isn't actually on this machine, you'll get a null result
$userDomain = (Get-WmiObject -Class Win32_useraccount -Filter "Name = '$userName'").Domain
$userSID = (Get-WmiObject -Class Win32_useraccount -Filter "Name = '$userName'").SID


#so the first thing we check for is a null domain. If that's the case, the user name entered wasn't valid
#Then we check for a domain that is not <our domain>. If it isn't, that's a local account, and we run "remove-localUser" against
##that user name. Even a local account will have a domain, it's the name of the computer. 
##finally if it is a domain account for <our domain>, then we run a different set of delete user actions

#Also, you have to use NT4 style domains here. so no "domainname.com", just "DOMAINNAME"

if ($userDomain -eq $null) {
     #Write-Warning $userName" isn't a local account on this machine"
     [Microsoft.VisualBasic.Interaction]::MsgBox("$userName is not a local account on this machine","OKOnly,SystemModal,Exclamation", "Warning")
     break
} elseif ($userDomain -ne "nt4domain") {
    #create the user files report
    #build the search name that will be used to find files with that user's ownership. 
    #NOTE: this requires even the local machine domain name, AND TAKES A WHILE, since it iterates through
    #every folder on the C drive. Most errors are caused by junction points
    $searchName = "$userDomain\$userName"

    #set the output file for the report
    $outFile = "C:\Users\Public\" + $userName + " file report.txt"

    #header for report
    Write-Host ("User file report for $userName" | Out-File `
			-Encoding "UTF8" `
			-FilePath $outFile -Append)

    #the start of the recursion
    $path = Get-ChildItem -Path C:\ -Recurse -Force

    #find every file owned by the specified user, and write that into the report
    #PLEASE note this isn't foolproof by any means, but if we really need to dig deeper, 
    #that's what redcloak is for
    Foreach( $file in $path ) {
	    $f = Get-Acl $file.FullName
	    if( $f.Owner -eq $searchName ) {
		    Write-Host( "{0}"-f $file.FullName | Out-File `
			    -Encoding "UTF8" `
			    -FilePath $outFile -Append)
	    }
    }

    #remove the user profile once the report is done
    Remove-LocalUser -Name $userName
    #check for a local home directory
    $userHome = Get-WmiObject -Query "Select * From Win32_Directory Where Name = 'C:\\Users\\$userName'"

    if ($userHome -eq $null) {
        #user home doesn't exist
        [Microsoft.VisualBasic.Interaction]::MsgBox("There is no user home directory for that user","OKOnly,SystemModal,Exclamation", "Warning")
        break
    } else {
        #user home does exist
        $userHome | Remove-WmiObject
        break
    }

} elseif ($userDomain -eq "nt4domain") {
    #get user files report as for a local user
    $searchName = "$userDomain\$userName"

    $outFile = "C:\Users\Public\" + $userName + " file report.txt"

    Write-Host ("User file report for $userName" | Out-File `
			-Encoding "UTF8" `
			-FilePath $outFile -Append)

    $path = Get-ChildItem -Path C:\ -Recurse -Force

    Foreach( $file in $path ) {
	    $f = Get-Acl $file.FullName
	    if( $f.Owner -eq $searchName ) {
		    Write-Host( "{0}"-f $file.FullName | Out-File `
			    -Encoding "UTF8" `
			    -FilePath $outFile -Append)
	    }
    }

    #even if it's a local profile for an AD user, you can't user Remove-LocalUser, they won't show up
    #get the profile object for the user with that SID
    $user = Get-WMIObject -Class Win32_UserProfile -Filter "SID = '$userSID'"
    #remove that object
    $user | Remove-WmiObject

    #check for a local home directory
    $userHome = Get-WmiObject -Query "Select * From Win32_Directory Where Name = 'C:\\Users\\$userName'"

    if ($userHome -eq $null) {
        #user home doesn't exist
        [Microsoft.VisualBasic.Interaction]::MsgBox("There is no user home directory for that user","OKOnly,SystemModal,Exclamation", "Warning")
        break
    } else {
        #user home does exist
        $userHome | Remove-WmiObject
        break
    }
}







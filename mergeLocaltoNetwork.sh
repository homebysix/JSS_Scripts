#!/bin/sh
####################################################################################################
#
# Copyright (c) 2013, JAMF Software, LLC.  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the JAMF Software, LLC nor the
#                 names of its contributors may be used to endorse or promote products
#                 derived from this software without specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
####################################################################################################
#
# HISTORY
#	Version: 1.2
#	- Added code by Ross Hamilton for function checkExistingBinding
#	Version: 1.1
#	- Fixed syntax in Functions; bindADCheck, moveHome, killFullscreen
#	Version: 1.0
#	- Created by Bram Cohen May 29, 2013
# 
# 
####################################################################################################
#
# DEFINE VARIABLES & READ IN PARAMETERS
#
####################################################################################################

# HARDCODED VALUES SET HERE
bindName="bind"


# CHECK TO SEE IF A VALUE WERE PASSED IN FOR PARAMETERS $3 THROUGH $9 AND, IF SO, ASSIGN THEM

if [ "$4" != "" ] && [ "$bindName" == "" ]; then
    bindName=$4
fi


####################################################################################################
# 
# SCRIPT CONTENTS - DO NOT MODIFY BELOW THIS LINE
#
####################################################################################################

####################################################################################################
# FUNCTION - Get information about the current user
#
# $current= - Get the active username
# $currentdir - Get the active username home directory
# $last - # of found records for the lastname
####################################################################################################
function identifyCurrent (){
	current="$(/usr/bin/stat -f '%u %Su' /dev/console | awk '{print $2}')"
	currentdir="/Users/$current"
}

####################################################################################################
# FUNCTION - Save information on the current user as plist
#
####################################################################################################
function createUserPlist (){
	if [ -e /Library/Application\ Support/JAMF/currentUser.plist ]; then
		/bin/rm -f /Library/Application\ Support/JAMF/currentUser.plist
	fi	
		/usr/bin/touch /Library/Application\ Support/JAMF/currentUser.plist
		/usr/bin/defaults write /Library/Application\ Support/JAMF/currentUser.plist currentUser $current
		/usr/bin/defaults write /Library/Application\ Support/JAMF/currentUser.plist currentHome $currentdir
}
####################################################################################################
# FUNCTION - Call Binding policy by Trigger
#
####################################################################################################
function bindAD (){
	/usr/sbin/jamf policy -trigger $bindName
}
####################################################################################################
# FUNCTION - Get Bind values for validation
#
# $adInfo - All AD binding information
# $adDomain - AD Domain address
# $adRequireConf - Home directory requires confirmation
# $adValidated
####################################################################################################
function bindADValues (){
	adInfo="$(/usr/sbin/dsconfigad -show)"
	adDomain="$(echo $adinfo | grep "Active Directory Domain" | awk '{print $NF}')"
	adRequireConf="$(echo $adinfo | grep "Require confirmation" | awk '{print $NF}')"
}
####################################################################################################
# FUNCTION - Redo bind if not bound, rinse repeat
####################################################################################################
function bindADCheck(){
	while [[ "$adInfo" == "" ]]; do
		bindAD
		bindADValues
	done
}
####################################################################################################
# FUNCTION - Prompt enduser for Username
#
# $adUsername - Username that was given by the end User
####################################################################################################
function promptForUsername(){
adUsername=`/usr/bin/osascript <<EOT
tell application "System Events"
    activate
    set adUsername to text returned of (display dialog "Please Input your Active Directory Username" default answer "" with icon 2)
end tell
EOT`
adUsername="$(echo $adUsername | tr '@' ' ' | awk '{print $1}')"
}
####################################################################################################
# FUNCTION - Re-query end user for Username
#
# $adUsername - Username that was given by the end User
####################################################################################################
function repromptForUsername(){
adUsername=`/usr/bin/osascript <<EOT
tell application "System Events"
    activate
    set adUsername to text returned of (display dialog "Please Re-Input your Active Directory Username" default answer "" with icon 2)
end tell
EOT`
adUsername="$(echo $adUsername | tr '@' ' ' | awk '{print $1}')"
}
####################################################################################################
# FUNCTION - Prompt enduser for Username
#
# $searchPath - Find the AD Search Path
# $adUserInfo - Get all AD Username Info
# $adPrimaryGroupID - Get the Primary AD Group ID
####################################################################################################
function checkADUsername(){
	adUserInfo="$(/usr/bin/dscl /Search -read /Users/$adUsername)"
	adPrimaryGroupID="$(echo $adUserInfo | grep "PrimaryGroupID" | awk '{print $NF}')"
}
####################################################################################################
# FUNCTION - Loop Prompt until we find a valid username
####################################################################################################
function validateADUsername(){
	while [[ "$adPrimaryGroupID" == "" ]]; do
		repromptForUsername
		checkADUsername
	done
	/usr/bin/defaults write /Library/Application\ Support/JAMF/currentUser.plist futureUser $adUsername
	/usr/bin/defaults write /Library/Application\ Support/JAMF/currentUser.plist futureHome /Users/$adUsername
}
####################################################################################################
# FUNCTION - Prompt User to confirm Logout
####################################################################################################
function promptUserToMove(){
	HELPER=1
	while [[ "$HELPER" != "2" ]]; do
		HELPER=`/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/Resources/Message.png -heading "Your Directory Account is almost Ready" -description "Would you like to migrate now?" -button2 "Yes" -button1 "No" -cancelButton "1"`
	done
	HELPER=1
}
####################################################################################################
# FUNCTION - Run fullscreen 
####################################################################################################
function startFullscreen(){
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType fs -icon /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/Resources/Message.png -heading "Your Directory Account is being migrated" -description "Please wait"
}
####################################################################################################
# FUNCTION - Move the target directory to the current directory and fix permissions
#
####################################################################################################
function moveHome(){
	readyToKill=0
	currentUser="$(/usr/bin/defaults read /Library/Application\ Support/JAMF/currentUser.plist currentUser)"
	currentDir="$(/usr/bin/defaults read /Library/Application\ Support/JAMF/currentUser.plist currentHome)"
	futureUser="$(/usr/bin/defaults read /Library/Application\ Support/JAMF/currentUser.plist futureUser)"
	futureDir="$(/usr/bin/defaults read /Library/Application\ Support/JAMF/currentUser.plist futureHome)"

	if [ -d "$currentDir" ]; then
		if [ -d "$futureDir" ]; then
			echo "Target Directory Exists, backing up,  then removing, and then Moving"
			/usr/sbin/jamf deleteAccount -username $futureUser
			/bin/mv $currentDir $futureDir
 			/usr/sbin/chown -R $futureUser:staff $futureDir
 			readyToKill=1
		else
			echo "Moving files from $currentDir to $futureDir"
			/bin/mv $currentDir $futureDir
 			/usr/sbin/chown -R $futureUser:staff $futureDir
 			
 		fi
 	else
 		echo "Current Directory not found, something is wrong here!"
	fi
	killFullscreen
}
####################################################################################################
# FUNCTION - Kill Fullscreen
####################################################################################################
function killFullscreen(){
	if [[ "$readyToKill" == "1" ]]; then
		fullpid="$(/bin/ps aux | grep j[a]mfHelper | awk '{print $2}')"
		kill -9 $fullpid
	fi
}
####################################################################################################
# FUNCTION - Inform User of the new Login Name
####################################################################################################
function informUser(){
	while [[ "$HELPER" != "2" ]]; do
		HELPER=`/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/Resources/Message.png -heading "Your Directory Account is now Ready" -description "You will be logged out shortly. At the login window, please use your new account name: $adUsername " -button2 "Okay" -button1 "Cancel" -cancelButton "1"`
	done
}
####################################################################################################
# FUNCTION - Logout Current User 
####################################################################################################
function logOut(){
	/bin/rm -f /Library/Application\ Support/JAMF/currentUser.plist
	/usr/bin/killall loginwindow
}

identifyCurrent
createUserPlist
bindAD
bindADValues
bindADCheck
promptForUsername
checkADUsername
validateADUsername
promptUserToMove
#startFullscreen
moveHome
#killFullscreen
informUser
logOut
echo "Complete"
exit 0

#!/bin/sh
###################################################################################################
#
# Copyright (c) 2015, JAMF Software, LLC.  All rights reserved.
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
###################################################################################################
#
# DESCRIPTION
#
#   This script is designed for a custom workflow to update local account passwords securely.
#
#	Recommended usage:
#		 - Specify User Variables in JSS Parameters
#		 - Set Script to Run on a timed basis
#		 - Set Update Inventory to run as part of policy
#
####################################################################################################
#
# HISTORY
#
#   - Created by Bram Cohen, JAMF Software, LLC, on September 30, 2015
#	- Updated by Bram Cohen, JAMF Software, LLC, on October 1, 2015
#		 - Fixed an issue where delimiters were present after decoding hash 
#		 - Fixed an issue where one could visually discern part of the string
#		 - Fixed an issue where the salt may cause a decode failure
#		 - Added additional notation and made the output pretty
#
####################################################################################################

###################################################################################################
# User Variable Section - Specify below or leave blank to fill in from the JSS in the next section
###################################################################################################

#Specify the user whose password will be updated
targetedUsername="testAdmin"

#Specify the length of password we would like to generate
lengthOfPassword="99"

#Specify a salt value to throw into the hash. THIS MUST BE SPECIFIED IN THE E.A. AS WELL
salt="giipecuimenn"

#Specify where you would like the hash stored on the machine
configurationFile="/Library/Preferences/com.jamfsoftware.management.plist"

###################################################################################################
# JSS Variable Section - If above are null and we have values from the JSS, it will them fill in
###################################################################################################
if [ "$4" != "" ] && [ "$targetedUsername" == "" ]; then
    targetedUsername="$4"
fi

if [ "$5" != "" ] && [ "$lengthOfPassword" == "" ]; then
    lengthOfPassword="$5"
fi

if [ "$6" != "" ] && [ "$salt" == "" ]; then
    salt="$6"
fi

if [ "$7" != "" ] && [ "$configurationFile" == "" ]; then
    configurationFile="$7"
fi


####################################################################################################
# Functions Section -  DO NOT MODIFY BELOW THIS LINE
####################################################################################################

###############################
# Function problemDetector
###############################
problemDetector() {
	if [[ "$problem" == "1" ]]; then
		echo "==================================================\n A problem was detected in this script run:\n"
		echo "$problemDescription"
		exit 1
	fi

}

###############################
# Function populateVariables
###############################
populateVariables() {
	binaryLocation=$(/usr/bin/type -a jamf | awk '{print $NF}')
	machineUUID=$(/usr/sbin/system_profiler SPHardwareDataType | grep UUID | awk '{print $NF}' | base64)

	if [ "$binaryLocation" == "" ]; then
		problem=1
		problemString=" - Unable to locate the jamf binary."
		problemDescription=$(echo "$problemDescription\n$problemString")
	fi
	if [ "$machineUUID" == "" ]; then
		problem=1
		problemString=" - Unable to locate locate the UUID of the computer."
		problemDescription=$(echo "$problemDescription\n$problemString")
	fi

}

###############################
# Function verifyUser
###############################
verifyUser() {
	userCheck=$(/usr/bin/dscl . -list /Users | grep "${targetedUsername}" | wc -l | awk '{print $NF}')

	if [ "$userCheck" == "0" ]; then
		problem=1
		problemString=" - Unable to locate the username $targetedUsername on this computer"
		problemDescription=$(echo "$problemDescription\n$problemString")
	fi	

}

###############################
# Function checkForConfig
###############################
checkForConfig() {
echo "Checking for Configuration File"
if [ ! -f "$configurationFile" ]; then
	echo " - Configuration not found, creating one"
	/usr/bin/touch $configurationFile
	/usr/sbin/chown root:wheel $configurationFile
else
	echo " - Configuration Found\n"
fi

}

###############################
# Function generatePassword
###############################
generatePassword() {

	echo "Generating Password"
	hundredDigits=$(/usr/bin/openssl rand -base64 100)
	passwordString=$(echo "${hundredDigits}" | tr -cd '[[:alnum:]]._-' | cut -c1-${lengthOfPassword})

}

###############################
# Function obfuscatePassword
###############################
obfuscatePassword() {

	echo " - Salting and Hashing password"
	saltPassword=$(echo "${machineUUID}${passwordString}${salt}" | base64)

}

###############################
# Function writePasswordToConfig
###############################
writePasswordToConfig() {
	echo " - Writing string to file\n"
	/usr/bin/defaults write $configurationFile string $saltPassword

	echo "Confirming hash was written in a readable manner"
	verifyHash=$(/usr/bin/defaults read $configurationFile string)

	if [ "$saltPassword" == "$verifyHash" ]; then
		echo " - Hash readability confirmed\n"
	else
		problem=1
		problemString=" - Failed to read the hash in the configuration file."
		problemDescription=$(echo "$problemDescription\n$problemString")
	fi

}

###############################
# Function changePassword
###############################
changePassword() {

	/usr/sbin/sysadminctl -resetPasswordFor ${targetedUsername} -newPassword ${passwordString} -passwordHint "Obtain in JSS" 2>/dev/null
	echo "Password has been changed"
}

###############################
# Function cleanUp
###############################

cleanUp() {
    
	variablesInUse="targetedUsername
	lengthOfPassword
	salt
	configurationFile
	problem
	problemString
	problemDescription
	binaryLocation
	machineUUID
	userCheck
	hundredDigits
	passwordString
	saltPassword
	verifyHash
	debugFlag"


    echo "Unsetting Variables\n"
    
    for vars in $variablesInUse; do
        unset $vars
    done

}

####################################################################################################
# Function Execution Section -  SERIOUSLY, DO NOT MODIFY BELOW THIS LINE UNLESS YOU KNOW WHATS UP!
####################################################################################################
echo "\n==========================================\n  Executing password randomization Script \n=========================================="

populateVariables
problemDetector
verifyUser
problemDetector
checkForConfig
generatePassword
obfuscatePassword
writePasswordToConfig
problemDetector
changePassword
cleanUp


echo "==========================================\n=========================================="
exit 0

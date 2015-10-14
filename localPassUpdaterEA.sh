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
#   This EA is designed for a custom workflow to update local account passwords via policy.
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
# User Variable Section 
###################################################################################################

#Specify the salt value used in the proceeding script. THIS MUST MATCH OR THE PROCESS WILL FAIL
salt="giipecuimenn"

#Specify the file where the script stores the hashed password
configurationFile="/Library/Preferences/com.jamfsoftware.management.plist"


####################################################################################################
# Function Execution Section
####################################################################################################

if [ ! -f "$configurationFile" ]; then
	echo "<result>Not Set</result>"
else
	machineUUID=$(/usr/sbin/system_profiler SPHardwareDataType | grep UUID | awk '{print $NF}' | base64)
	hashString=$(/usr/bin/defaults read $configurationFile string)
	echo "<result>$(echo "$hashString" | base64 --decode | sed "s/^${machineUUID}//" | sed "s/${salt}$//")</result>"
fi

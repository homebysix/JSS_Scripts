#!/bin/sh
############################################################################################################
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
############################################################################################################
#
# ABOUT THIS PROGRAM
#
# NAME
#  addJSSUserAsAdmin.sh -- Pulls JSS Username record for computer and elevates the permissions to local admin
#  if the current user is a match.
#
# SYNOPSIS
#	addJSSUserAsAdmin.sh
#	MSOffice11SetFirstRun.sh <mountPoint> <computerName> <loginUsername> <apiusername> <apipassword> <jssbase>
#
# DESCRIPTION
#	This script does an API call to JSS, retrieves Location>Username and elevates the user to Admin
#	if the current user matches the JSS Username.
#
############################################################################################################
#
# 2013-05-24--Created by Bram Cohen
#
############################################################################################################

# HARDCODED VARIABLES
apiusername="" # Username that has API privileges for 'Peripherals'
apipassword="" # Password for User that has API privileges for 'Peripherals'
jssbase="" # JSS base url e.g. "https://yourJSSurl:8443"

# CHECK FOR SCRIPT PARAMETERS IN JSS
if [ "$4" != "" ] && [ "$apiusername" == "" ]; then
	apiusername="$4"
fi

if [ "$5" != "" ] && [ "$apipassword" == "" ]; then
	apipassword="$5"
fi

if [ "$6" != "" ] && [ "$jssbase" == "" ]; then
	jssbase="$6"
fi

####################################################################################################
# SCRIPT FUNCTIONS -  - DO NOT MODIFY BELOW THIS LINE
####################################################################################################

#Get Current Username
currentUser="$(/usr/bin/stat -f '%u %Su' /dev/console | awk '{print $2}')"

#Get Active Interfaces
function getInterface() {
# Get interfaces Ethernet Addresses 
for iface in  `ifconfig -lu` ; do
    case $iface in
    en0)
    	en0="$(/sbin/ifconfig en0 | grep ether | awk '{print $NF}' | tr ':' '.')" ;;
    en1)
    	en1="$(/sbin/ifconfig en1 | grep ether | awk '{print $NF}' | tr ':' '.')" ;;
    esac
done
}

#Get Computer Details for interface en0
function getJSSInformationen0() {
/usr/bin/curl -k -u $apiusername:$apipassword $jssbase/JSSResource/computers/macaddress/$en0 -X GET | xmllint --format - >> /tmp/computerInfo.xml
jssUsername="$(cat /tmp/computerInfo.xml | xpath //computer/location/username | sed -e 's/\<username>//g; s/\<\/username>//g')"
/bin/rm -f /tmp/computerInfo.xml
}

#Get Computer Details for interface en1
function getJSSInformationen1() {
/usr/bin/curl -k -u $apiusername:$apipassword $jssbase/JSSResource/computers/macaddress/$en1 -X GET | xmllint --format - >> /tmp/computerInfo.xml
jssUsername="$(cat /tmp/computerInfo.xml | xpath //computer/location/username | sed -e 's/\<username>//g; s/\<\/username>//g')"
/bin/rm -f /tmp/computerInfo.xml
}

####################################################################################################
# SCRIPT OPERATIONS -  - REALLY!!! - DO NOT MODIFY BELOW THIS LINE
####################################################################################################

getInterface
if [ "$en0" != "" ]; then
	getJSSInformationen0
else
	getJSSInformationen1
fi
if [[ "$jssUsername" != "" ]]; then
	if [[ "$jssUsername" == "$currentUser" ]]; then
		if [ "`/usr/bin/dsmemberutil checkmembership -U $currentUser -G admin`" != "user is a member of the group" ]; then
			/usr/bin/dscl . merge /Groups/admin GroupMembership $currentUser
		else
			/bin/echo "$currentUser is already an admin"
		fi
	else
		/bin/echo "JSS Username:$jssUsername does not match Current Username:$currentUser"
	fi
else
	/bin/echo "Unable to find a valid MAC in JSS $en0,$en1"
fi

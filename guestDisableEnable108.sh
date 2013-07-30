#!/bin/bash
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
#  guestDisableEnable108.sh -- enables an account called Guest on the targeted system
#
# SYNOPSIS
#	guestDisableEnable108.sh 
#
# DESCRIPTION
#	This script does an enables a Guest user account if it does not exist or disables guest if it does exist.
#
############################################################################################################
#
# 2013-05-24--Created by Bram Cohen
# Based largely on work done at the following sites:
# https://github.com/nbalonso/Some_scripts/blob/master/Pushing%20Guest%20account/postflight.sh
# https://github.com/sheagcraig/guestAccount/blob/master/guest_account
#
############################################################################################################

##########################################################################################
# Variables
##########################################################################################
dscl="/usr/bin/dscl"
security="/usr/bin/security"


##########################################################################################
#Function to Enable the Guest User on the OS
##########################################################################################
function guest_enable {
  if [ -f /var/db/dslocal/nodes/Default/users/guest.plist ]; then
		echo "INFO: Guest was found on the system"
		echo "INFO: Exiting now"
	else
		if [ "$(sw_vers | grep -o '10\.[7-8]')" != "" ]; then 	
			$dscl . -create /Users/guest 2>/dev/null
			$dscl . -create /Users/guest dsAttrTypeNative:_defaultLanguage en 2>/dev/null
			$dscl . -create /Users/guest dsAttrTypeNative:_guest true 2>/dev/null
			$dscl . -create /Users/guest dsAttrTypeNative:_writers__defaultLanguage Guest 2>/dev/null		
			$dscl . -create /Users/guest dsAttrTypeNative:_writers_LinkedIdentity Guest 2>/dev/null		
			$dscl . -create /Users/guest dsAttrTypeNative:_writers_UserCertificate Guest 2>/dev/null		
			$dscl . -create /Users/guest AuthenticationHint '' 2>/dev/null
			$dscl . -create /Users/guest NFSHomeDirectory /Users/Guest 2>/dev/null
			#setting up an empty password and giving local Kerberos some time to process it
			sleep 2
			$dscl . -passwd /Users/guest '' 2>/dev/null
			sleep 2
			$dscl . -create /Users/guest Picture "/Library/User Pictures/Nature/Leaf.tif" 2>/dev/null
			$dscl . -create /Users/guest PrimaryGroupID 201 2>/dev/null
			$dscl . -create /Users/guest RealName "Local Guest" 2>/dev/null
			$dscl . -create /Users/guest RecordName guest 2>/dev/null
			#Lion does not like two users with same UUID so don't use 201 on the next line
			$dscl . -create /Users/guest UniqueID 401 2>/dev/null
			$dscl . -create /Users/guest UserShell /bin/bash 2>/dev/null
			#Adding the keychain item that allows Guest to login in 10.7
			$security add-generic-password -a guest -s com.apple.loginwindow.guest-account -D 'application password' /Library/Keychains/System.keychain
			#logging in console
		fi
	fi
}

##########################################################################################
#Function to Disable the Guest User on the OS
##########################################################################################
function guest_disable {
if [ -f /var/db/dslocal/nodes/Default/users/guest.plist ]; then
	echo "INFO: Guest was found on the system"
	$dscl . -delete /Users/guest
	$security delete-generic-password -a guest -s com.apple.loginwindow.guest-account -D 'application password' /Library/Keychains/System.keychain
	# Also-do we need this still? (Should un-tick the box)
	defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool FALSE
	# Doesn't have an effect, but here for reference
	#defaults write /Library/Preferences/com.apple.loginwindow DisableGuestAccount -bool TRUE
	#defaults write /Library/Preferences/com.apple.loginwindow EnableGuestAccount -bool FALSE
	exit 0
else
	echo "INFO: Guest was NOT found on the system"
fi
}

##########################################################################################
# Handle the arguments
##########################################################################################

# Determine what to do
guest_disable
guest_enable

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
#  MSOffice11SetFirstRun.sh -- Dismisses first run dialogs in MS Office 2011 deployments
#
# SYNOPSIS
#	MSOffice11SetFirstRun.sh
#	MSOffice11SetFirstRun.sh <mountPoint> <computerName> <loginUsername> <company>
#
# DESCRIPTION
#	This script sets the first-run plist's for each user on the computer.
#	Useful for deployments that do not already have these items set.
#
############################################################################################################
#
# Created by Bram Cohen
# Adapted from Marcus Jaensson http://deploywiz.blogspot.com/2010/11/get-rid-of-office-2011s-first-run.html
# 2013-05-14--Added more relevant MCX from http://www.officeformachelp.com/office/administration/mcx/
#
############################################################################################################
# Define Company Name to use in registration
company=""

# If filled from JSS and not set above, use JSS.
if [ "$4" != "" ] && [ "$company" == "" ]
then
	company="$4"
fi

# Pull the Current User to use in registration
current="$(/usr/bin/stat -f '%u %Su' /dev/console | awk '{print $2}')"

for d in /Users/*
do
	user="$(echo $d | tr '/' ' ' | awk '{print $2}')"
	# Disable Office FirstRun
    defaults write $d/Library/Preferences/com.microsoft.office.plist "14\\FirstRun\\SetupComplete" -int 1
    defaults write $d/Library/Preferences/com.microsoft.office.plist "14\UserInfo\UserName" -string $current
    defaults write $d/Library/Preferences/com.microsoft.office.plist "14\UserInfo\UserOrganization" -string $company
    defaults write $d/Library/Preferences/com.microsoft.autoupdate2.plist "HowToCheck" -string "Manual"
    defaults write $d/Library/Preferences/com.microsoft.autoupdate2.plist "LastUpdate" -date "2001-01-01T00:00:00Z"
    defaults write $d/Library/Preferences/com.microsoft.error_reporting.plist "SQMReportsEnabled" -bool false
    defaults write $d/Library/Preferences/com.microsoft.error_reporting.plist "ShipAssertEnabled" -bool false
    # Hide welcome windows
    defaults write $d/Library/Preferences/com.microsoft.Excel.plist "14\Microsoft Excel\Hide Welcome Window" -int 1
    defaults write $d/Library/Preferences/com.microsoft.Outlook.plist "FirstRunExperienceCompleted" -bool true
    defaults write $d/Library/Preferences/com.microsoft.PowerPoint.plist "14\Options\Options\Hide Welcome Dialog" -int 1
    defaults write $d/Library/Preferences/com.microsoft.Word.plist '14\Options\Hide Welcome Dialog' -int 1
    # Fix Permissions
    chown $user:staff $d/Library/Preferences/com.microsoft.*
done

exit 0

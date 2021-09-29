#! /bin/sh

sudo launchctl unload /Library/LaunchDaemons/com.test.PkgUIHelper.plist
sudo rm /Library/LaunchDaemons/com.test.PkgUIHelper.plist
sudo rm /Library/PrivilegedHelperTools/com.test.PkgUIHelper

sudo security -q authorizationdb remove "/Library/LaunchDaemons/com.test.PkgUIHelper.installPkg"

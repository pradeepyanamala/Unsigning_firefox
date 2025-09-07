#!/bin/sh

set -e

## Prepare
echo '**** Preparing... ****'

# Get Revision Of Firefox Snap
REV="$(snap list | grep firefox | awk '{print $3}')"

# Get Snap File
FILE="/var/lib/snapd/snaps/firefox_${REV}.snap"

# Unmount Snap
sudo systemctl stop "snap-firefox-${REV}.mount"
sudo /usr/lib/snapd/snap-discard-ns firefox

# Create Workdir
rm -rf /tmp/jailbreak-firefox-snap-workdir
mkdir /tmp/jailbreak-firefox-snap-workdir
cd /tmp/jailbreak-firefox-snap-workdir

## Modify
echo '**** Modifying... ****'

# Extract Snap
sudo chmod o+r "${FILE}"
unsquashfs -d snap "${FILE}"

# Extract omni.ja
mkdir omni
unzip -q snap/snap/firefox/current/usr/lib/firefox/omni.ja -d omni || : # Ignore Errors

# Patch AppConstants.jsm
sed -i 's/MOZ_REQUIRE_SIGNING:.*/MOZ_REQUIRE_SIGNING: false, _old_require_signing:/' omni/modules/AppConstants.sys.mjs

# Repackage omni.ja
rm -f snap/snap/firefox/current/usr/lib/firefox/omni.ja
cd omni
zip -0DXqr ../snap/snap/firefox/current/usr/lib/firefox/omni.ja . # Source: https://stackoverflow.com/a/68379534
cd ../

# Rebuild Snap
sudo rm -f "${FILE}"
sudo mksquashfs snap "${FILE}" -noappend -comp lzo -no-fragments

## Finalize
echo '**** Finalizing... ****'

# Mount Snap
sudo systemctl start "snap-firefox-${REV}.mount"

# Clean Up
rm -rf /tmp/jailbreak-firefox-snap-workdir

## Done
echo '**** Done! ****'

#!/bin/sh

set -e

## Prepare
echo '**** Preparing... ****'

# Create Workdir
rm -rf /tmp/jailbreak-firefox-system-workdir
mkdir /tmp/jailbreak-firefox-system-workdir
cd /tmp/jailbreak-firefox-system-workdir

## Modify
echo '**** Modifying... ****'

# Extract omni.ja
mkdir omni
unzip -q /usr/lib/firefox/omni.ja -d omni || : # Ignore Errors

# Patch AppConstants.jsm
sed -i 's/MOZ_REQUIRE_SIGNING:.*/MOZ_REQUIRE_SIGNING: false, _old_require_signing:/' omni/modules/AppConstants.sys.mjs

# Repackage omni.ja
sudo rm -f /usr/lib/firefox/omni.ja
cd omni
sudo zip -0DXqr /usr/lib/firefox/omni.ja . # Source: https://stackoverflow.com/a/68379534
cd ../

## Finalize
echo '**** Finalizing... ****'

# Clean Up
rm -rf /tmp/jailbreak-firefox-system-workdir

## Done
echo '**** Done! ****'

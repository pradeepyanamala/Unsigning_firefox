#!/bin/bash
set -e
set -o pipefail

echo "**** Starting Firefox Snap extraction and patch ****"

# Step 1: Get Firefox snap revision
REV="$(snap list firefox | awk '/firefox/ {print $3}')"
if [ -z "$REV" ]; then
  echo "ERROR: Could not find Firefox snap revision."
  exit 1
fi
echo "Firefox snap revision: $REV"

SNAP_FILE="/var/lib/snapd/snaps/firefox_${REV}.snap"

if [ ! -f "$SNAP_FILE" ]; then
  echo "ERROR: Snap file $SNAP_FILE does not exist."
  exit 1
fi

# Step 2: Prepare working directory
WORKDIR="/tmp/firefox-unsquash"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

echo "Extracting snap..."
unsquashfs -d "$WORKDIR" "$SNAP_FILE"

# Step 3: Extract omni.ja
OMNI_DIR="$WORKDIR/usr/lib/firefox/omni"
mkdir -p "$OMNI_DIR"
unzip -q "$WORKDIR/usr/lib/firefox/omni.ja" -d "$OMNI_DIR"

# Step 4: Patch AppConstants.sys.mjs to disable signature requirement
APPCONST="$OMNI_DIR/modules/AppConstants.sys.mjs"

if [ ! -f "$APPCONST" ]; then
  echo "ERROR: $APPCONST not found."
  exit 1
fi

echo "Patching AppConstants.sys.mjs to disable MOZ_REQUIRE_SIGNING..."
sed -i 's/MOZ_REQUIRE_SIGNING:.*/MOZ_REQUIRE_SIGNING: false, _old_require_signing:/' "$APPCONST"

# Step 5: Repack omni.ja
echo "Repacking omni.ja..."
cd "$OMNI_DIR"
zip -0DXqr ../omni.ja . 
cd -

# Step 6: Run Firefox from extracted folder
echo "Running Firefox from extracted snap..."
"$WORKDIR/usr/lib/firefox/firefox"

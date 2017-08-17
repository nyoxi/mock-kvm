#!/bin/bash -ex

. /rpm-build-config

MOCK_BIN=/usr/bin/mock
MOCK_CONF_DIR=/etc/mock
BUILD_BASE=/rpmbuild
OUTPUT_DIR=$BUILD_BASE/output
CACHE_DIR=$BUILD_BASE/cache

mkdir -p "$OUTPUT_DIR" "$CACHE_DIR"

mkdir -p ~/.mock
restorecon ~/.mock
cat > ~/.mock/user.cfg <<EOT
config_opts['cache_topdir'] = '$CACHE_DIR'
EOT

if [ -z "$MOCK_CONFIG" ]; then
        echo "MOCK_CONFIG is empty. Should be one of:"
        ls -l $MOCK_CONF_DIR
        exit 1
fi

if [ ! -f "${MOCK_CONF_DIR}/${MOCK_CONFIG}.cfg" ]; then
        echo "MOCK_CONFIG is invalid. Should be one of:"
        ls -l $MOCK_CONF_DIR
        exit 1
fi

# Configure auxiliary repository
if [ ! -z "$AUX_REPO" ]; then
    cat >> ~/.mock/user.cfg <<EOT
config_opts['yum.conf'] += """
[custom]
name=Additional repository
baseurl=$AUX_REPO
"""
EOT
fi

# Configure local repository with results
if [ ! -z "$LOCAL_REPO" ] ; then
    cat >> ~/.mock/user.cfg <<EOT
config_opts['yum.conf'] += """
[local-results-repo]
name=Local results repository
baseurl=file://$BUILD_BASE/repo
skip_if_unavailable=1
"""
EOT
fi

echo "==  Build Configuration:"
echo "Environment:      $MOCK_CONFIG"
echo "Additional repo:  $AUX_REPO"

if [ ! -z "$SPEC" ]; then
        echo "Building from:    spec file + dist archive"
        echo "Spec file:        $SPEC"
        echo "Source archive:   $SOURCES"
        set -x
        "$MOCK_BIN" -r $MOCK_CONFIG --buildsrpm \
            --spec="$BUILD_BASE/SPECS/$SPEC" \
            --sources="$BUILD_BASE/SOURCES/$SOURCES" \
            --resultdir="$OUTPUT_DIR" \
            --no-cleanup-after
        RPM="$(find "$OUTPUT_DIR" -type f -name "*.src.rpm")"
        "$MOCK_BIN" -r $MOCK_CONFIG --rebuild \
            "$RPM" \
            --resultdir="$OUTPUT_DIR" \
            --no-cleanup \
            --no-cleanup-after
        set +x
else
    echo "No action specified!"
    exit 2
fi

echo
echo "Done."

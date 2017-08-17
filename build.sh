#! /bin/sh -e

WD=""
if [ "$(dirname "$0")" != "." ] ; then
    WD="$(readlink -f .)/"
    cd "$(dirname "$0")"
fi

######

MOCK_CONFIG=epel-7-x86_64
VM_TEMPLATE="$(readlink -f .)/rpm-builder.qcow2"
BUILD_BASE="/rpmbuild"
BASEDIR=/home/rpmbuild
VM_POOL="$BASEDIR/vms"
REPO_DIR="$BASEDIR/repo"

######

if [ $# -lt 2 ] ; then
    echo "Usage: [-c <mock_config>] <package.spec> <source.tar.gz> [<auxiliary_repo>]" >&2
    exit 1
fi

if [ "$1" == '-c' ] ; then
    MOCK_CONFIG="$2"
    shift; shift
fi

SPEC="${WD}$1"
SRC="${WD}$2"
shift; shift

AUX_REPO=
if [ $# -gt 0 ] ; then
    AUX_REPO="$1"
    shift
fi

######

mkdir -p "$VM_POOL"
VM="$(mktemp --tmpdir="$VM_POOL" build-XXXXXXXXXX.qcow2)"
VM_CONFIG="$(mktemp)"

echo ":: VM location: $VM"
qemu-img create -f qcow2 -b "$VM_TEMPLATE" "$VM"

cat > "$VM_CONFIG" <<EOT
MOCK_CONFIG='$MOCK_CONFIG'
SOURCE='$(basename "$SRC")'
SPEC='$(basename "$SPEC")'
AUX_REPO='$AUX_REPO'
LOCAL_REPO=1
EOT

mkdir -p "$REPO_DIR/$MOCK_CONFIG"

echo ":: Configuring build VM"
virt-customize -a "$VM" \
    --upload "$VM_CONFIG:/rpm-build-config" \
    --upload "$SRC:/$BUILD_BASE/SOURCES/" \
    --upload "$SPEC:/$BUILD_BASE/SPECS/"

echo ":: Starting build VM"
qemu-system-x86_64 \
    -machine accel=kvm:tcg \
    -m 2048 \
    -enable-kvm \
    -nographic \
    -drive "file=$VM,format=qcow2,if=virtio,index=0,media=disk" \
    -netdev user,id=net0 \
    -device virtio-net-pci,netdev=net0 \
    -fsdev "local,id=cache_dev,path=$BASEDIR/cache,security_model=none" \
    -device "virtio-9p-pci,fsdev=cache_dev,mount_tag=cache_mount" \
    -fsdev "local,id=repo_dev,path=$REPO_DIR/$MOCK_CONFIG,security_model=none" \
    -device "virtio-9p-pci,fsdev=repo_dev,mount_tag=repo_mount" \
    -object rng-random,id=rng_dev,filename=/dev/random \

echo ":: Build guest finished!"
echo "::     VM was: $VM"

echo ":: Copying out results"
mkdir -p "$BASEDIR/output/$MOCK_CONFIG"
guestfish add "$VM" \
    : run \
    : mount /dev/sda3 / \
    : glob copy-out "$BUILD_BASE/output/*.rpm"  "$REPO_DIR/$MOCK_CONFIG"


echo ":: Updating repository metadata"
pushd "$REPO_DIR/$MOCK_CONFIG" >/dev/null
createrepo_c --update .
popd >/dev/null

echo ":: Finished"

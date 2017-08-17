#! /bin/sh -e
BUILDER_UID=1000
BUILDER_GID=1000
BUILD_BASE=/rpmbuild

cd "$(dirname "$0")"

virt-builder --smp 2 \
    fedora-25 --arch 'x86_64' \
    --output 'rpm-builder.qcow2' \
    --format 'qcow2' \
    --hostname 'rpm-builder' \
    --root-password 'password:' \
    --install 'mock' \
    --install 'rpm-sign' \
    --install 'expect' \
    --install 'findutils' \
    --upload 'guest/build-rpm.sh:/build-rpm.sh' \
    --chmod '0755:/build-rpm.sh' \
    --run-command 'chown root: /build-rpm.sh' \
    --mkdir "$BUILD_BASE" \
    --mkdir "$BUILD_BASE/SPECS" \
    --mkdir "$BUILD_BASE/SOURCES" \
    --mkdir "$BUILD_BASE/cache" \
    --mkdir "$BUILD_BASE/repo" \
    --run-command "chown -R $BUILDER_UID:$BUILDER_GID $BUILD_BASE" \
    --run-command "echo 'cache_mount /$BUILD_BASE/cache 9p trans=virtio,version=9p2000.L,posixacl,cache=loose 0 0' >> /etc/fstab" \
    --run-command "echo 'repo_mount /$BUILD_BASE/repo 9p trans=virtio,version=9p2000.L,posixacl,cache=loose 0 0' >> /etc/fstab" \
    --upload 'guest/9p-modules.conf:/etc/modules-load.d/' \
    --chmod '0644:/etc/modules-load.d/9p-modules.conf' \
    --run-command 'chown root: /etc/modules-load.d/9p-modules.conf' \
    --upload 'guest/build-rpm.service:/etc/systemd/system/' \
    --run-command 'chown root: /etc/systemd/system/build-rpm.service' \
    --mkdir '/etc/systemd/system/default.target.wants' \
    --link '/etc/systemd/system/build-rpm.service:/etc/systemd/system/default.target.wants/build-rpm.service' \
    --firstboot-command "groupadd -g $BUILDER_GID builder" \
    --firstboot-command "useradd -m -p '' -u $BUILDER_UID -g builder -G mock builder" \
    --edit '/etc/sysconfig/selinux:s/^SELINUX=.*/SELINUX=permissive/'

# TODO: fix SELinux
#    --selinux-relabel

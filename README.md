# mock-kvm

This is a set of scripts that enable you to build RPM inside a virtual machine
run with QEMU/KVM.

To use it you will need:

* QEMU with KVM support
* libguestfs tools
* createrepo\_c


## Installation and Use

First you must build the template for the VMs. To do that run:

        $ ./vm-template.sh

This will create a virtual machine in `rpm-builder.qcow2`. This will be used as
a template for VMs used during builds.

To actually build a RPM invoke the build command:

        $ ./build.sh some-package.spec some-package.tar.gz

This will build the packages specified in the `some-package.spec` file from
sources in `some-package.tar.gz`. Once the build VM is up and running you will
see the login prompt. Don't get fooled by this and patiently wait. The build
process is running in the background.

To update the template VM at any time later run:

        $ virt-customize -a rpm-builder.qcow2 --update


## TODO

* move configuration into single file
* remove login prompt
* enable SELinux -- fix the issues related to SELinux and re-enable it
* show logs at runtime -- tail all logs in tmux or something
* disable grub timeout to speed up the strart

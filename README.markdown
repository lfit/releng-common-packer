# Common Packer

The purpose of this repo is to store commonly used packer provisioning scripts
and even instance templates that projects may use.

## Installing lf-ansible

common-packer requires first lf-ansible to be installed separately. To install
lf-ansible load it into the root of the ci-management repository as a
submodule. lf-ansible is versioned so will allow easy updates and rollback if
necessary.

```bash
# Choose a common-packer version to install
LF_ANSIBLE_VERSION=v0.1.0

# Add the new submodule to ci-management's packer directory.
# Note: Perform once per ci-management repo.
git submodule add https://github.com/lfit/lf-ansible

# Checkout the version of common-packer you wish to deploy
cd lf-ansible
git checkout $LF_ANSIBLE_VERSION

# Commit common-packer version to the ci-managment repo
cd ..
git add lf-ansible
git commit -sm "Install common-packer $LF_ANSIBLE_VERSION"

# Push the patch to ci-management for review
git review
```

## Installing common-packer

Deploy common-packer in the ci-management repository's packer directory as a
submodule. Installing, upgrading, and rolling back changes is simple via the
versioned git tags.

```bash
# Choose a common-packer version to install
COMMON_PACKER_VERSION=v0.1.0

# Add the new submodule to ci-management's packer directory.
# Note: Perform once per ci-management repo.
cd packer/
git submodule add https://github.com/lfit/common-packer

# Checkout the version of common-packer you wish to deploy
cd common-packer
git checkout $COMMON_PACKER_VERSION

# Commit common-packer version to the ci-managment repo
cd ../..
git add packer/common-packer
git commit -sm "Install common-packer $COMMON_PACKER_VERSION"

# Push the patch to ci-management for review
git review
```

## Using common-packer

To use any provisioning script available from the common-packer repository, the
calling template must appropriately reference the full path to the script.  In
most cases this is 'provision/$SCRIPT' which is will now be
'common-packer/provision/$SCRIPT'

To use any of the provided templates, the template should have a symlink into
the calling project's templates directory. This is because our common-packer
job scripts operate on the templates available in this directory. Any template,
except the 'builder', will also look for local customization out of the local
repository's provisioning with both a directory as well as script exec.

Distro specific vars are now provided in 'common-packer/vars/$DISTRO' and do
not need to be linked over just path to them when calling the packer cli.

## Example template design and run

In most cases the 'builder' template unmodified is all that the project should
need to run their code builds. If a project has a custom packages that they
must build into a custom builder type then a new template should be designed
with the following parameters.

0. Execute the common-packer/provision/install-python.sh script
1. Execute the common-packer/provision/baseline.yaml Ansible playbook
2. Execute a local playbook
3. Execute the system reseal Ansible role

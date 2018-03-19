# Common Packer

The purpose of this repo is to store commonly used packer provisioning scripts
and even instance templates that projects may use.

## Installing lf-ansible

common-packer requires an lf-ansible installation into the ci-management root.
To install lf-ansible load it into the root of the ci-management repository as
a submodule. Versioned git tags for lf-ansible is available allowing easy
updates and rollback if necessary.

```bash
# Choose a lf-ansible version to install
LF_ANSIBLE_VERSION=v0.1.0

# Add the new submodule to ci-management's packer directory.
# Note: Perform once per ci-management repo.
git submodule add https://github.com/lfit/releng-lf-ansible

# Checkout the version of lf-ansible you wish to deploy
cd releng-lf-ansible
git checkout $LF_ANSIBLE_VERSION

# Commit releng-lf-ansible version to the ci-managment repo
cd ..
git add releng-lf-ansible
git commit -sm "Install releng-lf-ansible $LF_ANSIBLE_VERSION"

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
will also look for local customization out of the local repository's
provisioning directory via local-$TEMPLATE.yaml playbook.

Distro specific vars are now provided in 'common-packer/vars/$DISTRO'.
Path to them as normal and they will already contain the correct strings. For
a new project make sure the base_image name is available in the cloud system.

## Example template design and run

In most cases the 'builder' template unmodified is all that the project should
need to run their code builds. If a project has a custom packages that they
must build into a custom builder type then design the new template with the
following parameters.

0. Execute the common-packer/provision/install-python.sh script
1. Execute the common-packer/provision/baseline.yaml Ansible playbook
2. Execute a local playbook
3. Execute the system reseal Ansible role

Steps 1-3 are actually all contained inside of the local playbook. Please refer
to the docker template and provisioning script for an example of how it imports
the existing baseline playbook into the local playbook to reduce duplication in
code.

## Installing Roles from Ansible Galaxy

Common-packer contains a script `ansible-galaxy.sh` which runs
`ansible-galaxy install -r requirements.yaml` from the common-packer repo to
install common-packer role dependencies. In the local
ci-management/packer directory a project can provide it's own requirements.yaml
to pull in roles before running a Packer build.

## Local testing of common-packer

For developers of common-packer who would like to be able to locally test from
the common-packer repo. Clone both common-packer and releng-lf-ansible in the same
directory and the scripts will handle the relative paths to both itself
(common-packer) and releng-lf-ansible respectively.

If you are trying to bootstrap an image inside the LF network follow the next
step.

## Getting through the LF network

0. Connect to the VPN
1. Configure ~/.ssh/config to proxy through a known server (such as Jenkins Sandbox)

For example:

```
Host 10.30.18*
  ProxyCommand ssh vex-yul-acumos-jenkins-2.ci.codeaurora.org nc %h 22
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
```

2. Set `ssh_proxy_host` to **127.0.0.1** in vars/cloud-env.json
3. Create a SOCKS 5 proxy on port 1080

   ssh -fND 1080 vex-yul-odl-jenkins-2.ci.codeaurora.org

4. Run packer as usual

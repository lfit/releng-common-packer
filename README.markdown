# Common Packer

The purpose of this repo is to store commonly used packer provisioning scripts
and even instance templates that may be reused by projects.

## Installing common-packer

Deploy common-packer in the ci-management repository's packer directory as a
submodule. Installing, upgrading, and rolling back changes is simple via the
versioned git tags.

```
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

To utilize any provisioning script available from the common-packer repository,
the calling template must appropriately reference the full path to the script.
Normally this is just 'provision/$SCRIPT' this would be modified to
'common-packer/provision/$SCRIPT'

To utilize any of the provided templates, the template should be symlinked into
the calling project's templates directory. This is because our global-jjb packer
scripts only operate on the templates available in this directory. Any template,
with the exception of baseline, will also look for local customization out of
the local repository's provisioning with both a directory as well as script
exec.

## Example template design and run

A common template that many of our projects use is called 'basebuild' this
template will do the following:

1. Copy the provision/basebuild directory, which must exist in the parent
   project, to /tmp/packer
2. Execute the common baseline provisioning script
3. Execute the common basebuild provisioning script
4. Execute the local (provision/basebuild) provisioning script. This script may
   execute any additional scripts that it needs out of the /tmp/packer directory
   that was copied to the system
5. Execute the common system reseal script

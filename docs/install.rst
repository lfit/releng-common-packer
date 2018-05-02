#####################
Install Common Packer
#####################

Deploy common-packer in the ci-management repository's packer directory as a
submodule. Installing, upgrading, and rolling back changes is simple via the
versioned git tags.

#. Choose a common packer version to install

   .. code-block:: bash

      COMMON_PACKER_VERSION=v0.1.0

#. Clone common-packer into ci-management repo

   .. code-block:: bash

      cd packer/
      git submodule add https://github.com/lfit/releng-common-packer common-packer

      # Checkout the version of common-packer you wish to deploy
      cd common-packer
      git checkout $COMMON_PACKER_VERSION

#. Commit common-packer version to the ci-managment repo

   .. code-block:: bash

      cd ../..
      git add packer/common-packer
      git commit -sm "Install common-packer $COMMON_PACKER_VERSION"

#. Push the patch to ci-management for review

   .. code-block:: bash

      git review

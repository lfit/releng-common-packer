###################
Common Packer Usage
###################

To use any provisioning script available from the common-packer repository, the
calling template must appropriately reference the full path to the script. In
most cases this is 'provision/$SCRIPT' which is now
'common-packer/provision/$SCRIPT'

To use any of the provided templates, the template should have a symlink into
the calling project's templates directory. This is because our common-packer
job scripts operate on the templates available in this directory. Any template,
will also look for local customization out of the local repository's
provisioning directory via local-$TEMPLATE.yaml playbook.

Distribution specific vars are now provided in 'common-packer/vars/$DISTRO'.
Path to them as normal and they will already contain the correct strings. For
a new project make sure the base_image name is available in the cloud system.

.. _setup-template:

Setup packer template
=====================

This setups up a builder image for use in a project. Repeat for any other
templates provided by common-packer as necessary.

.. code-block:: bash

   # Instructions assume the working directory is the ci-management repo root
   cd packer
   mkdir provision templates
   ln -rs common-packer/templates/builder.pkr.hcl templates/builder.pkr.hcl
   cp common-packer/provision/local-builder.yaml provision/local-builder.yaml

.. _custom-template:

Example template design and run
===============================

In most cases the 'builder' template unmodified is all that the project should
need to run their code builds. If a project has a custom package that they
must build into a custom builder type then design the new template with the
following parameters:

#. Execute the common-packer/provision/install-python.sh script
#. Execute the common-packer/provision/baseline.yaml Ansible playbook
#. Execute a local playbook
#. Execute the system reseal Ansible role

Steps 2-4 are actually all contained inside of the local playbook. The
following examples for ``docker template`` and ``provisioning script`` show how
they import the existing baseline playbook into the local playbook to reduce
duplication in code.

Example docker template:

.. literalinclude:: ../templates/docker.json
   :language: json

Example provisioning script:

.. literalinclude:: ../provision/docker.yaml
   :language: yaml

.. _install-from-ansible-galaxy:

Install Roles from Ansible Galaxy
=================================

Common-packer contains a script `ansible-galaxy.sh` which runs
`ansible-galaxy install -r requirements.yaml` from the common-packer repo to
install common-packer role dependencies. In the local
ci-management/packer directory a project can provide it's own requirements.yaml
to pull in roles before running a Packer build.

.. _local-testing:

Local testing of common-packer
==============================

For developers of common-packer who would like to be able to locally test from
the common-packer repo, the common-packer repository already contains a symlink
to itself which allows one to test the templates in the common-packer templates
standalone.

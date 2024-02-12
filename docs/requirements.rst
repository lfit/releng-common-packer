############
Requirements
############

* Ansible 2.15.9 or later
* Packer 1.9.1 or later

Install Ansible via pip in a virtualenv to build images.

.. code-block:: bash

    virtualenv -p $(which python3) ~/venv/.ansible
    source ~/venv/.ansible/bin/activate
    pip3 install ansible~=2.15.9

############
Requirements
############

* Ansible 2.9.27 or later
* Packer 1.8.2 or later

Install Ansible via pip in a virtualenv to build images.

.. code-block:: bash

    virtualenv -p $(which python3) ~/venv/.ansible
    source ~/venv/.ansible/bin/activate
    pip3 install ansible~=2.9.27

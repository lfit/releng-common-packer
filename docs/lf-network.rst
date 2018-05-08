##########
LF Network
##########

.. note::

   This doc is relevant to LF staff who have access to the VPN network.

To bootstrap an image inside the LF network the packer configuration contains
an ``ssh_proxy_host`` variable to connect to a SOCKS5 proxy through a known
system such as Jenkins to connect to the VM instance on the network.

Connect through the LF network
==============================

#. Connect to the VPN
#. Set ``ssh_proxy_host`` to **127.0.0.1** in vars/cloud-env.json
#. Create a SOCKS 5 proxy on port 1080

   .. code-block:: bash

      ssh -fND 1080 vex-yul-odl-jenkins-2.ci.codeaurora.org

   Replace the server ``vex-yul-odl-jenkins-2.ci.codeaurora.org`` with a known
   server for the relevant project.

#. Run packer as usual

.. note::

    If forwarding your ssh-agent and you have more than one ssh key, you may
    see this error message:

    .. literalinclude:: lf-network-ssh-multi-key-fail.txt
       :language: bash

    To resolve this start the ssh SOCKS proxy with your agent first, stop your
    agent, then run packer.

**Bonus**

If you would like to be able to ssh directly to a dynamic system inside of the
LF Network add the following to ``~/.ssh/config``:

.. code-block:: bash

   Host 10.30.18*
     ProxyCommand ssh vex-yul-acumos-jenkins-2.ci.codeaurora.org nc %h 22
     StrictHostKeyChecking no
     UserKnownHostsFile /dev/null

Replace the server ``vex-yul-acumos-jenkins-2.ci.codeaurora.org`` with a known
server for the relevant project.

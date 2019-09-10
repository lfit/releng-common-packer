#####################
Update Packer Images
#####################

Workflow:

Change is merged to an ansible role:
https://gerrit.linuxfoundation.org/infra/c/ansible/roles/lf-recommended-tools/+/16671

Now we want the images in our "umbrella-project's" openstack cloud to have these changes:

So we find the packer merge jobs in our umbreall project's jenkins.
Trigger this job for each builder you want to be able to update.

https://jenkins.umbrealla-name.org/search/?q=packer-merge

    ci-management-packer-merge-centos-7-docker
    ci-management-packer-merge-centos-7-builder
    ci-management-packer-merge-ubuntu-18.04-docker
    ci-management-packer-merge-ubuntu-18.04-builder


Now we trigger a merge job for each builder that we want to update.
https://jenkins.acumos.org/job/ci-management-packer-merge-centos-7-builder/


Or if you dont have trigger:

you can run a remerge via comment on a change (anyone can do this) to for example:
umbrealla-project/ci-management/packer/vars/centos-7.json

example:
https://gerrit.acumos.org/r/c/ci-management/+/5041/1/packer/vars/centos-7.json

and that will trigger both builds:
ci-management-packer-merge-centos-7-docker
ci-management-packer-merge-centos-7-builder
 

When the job is complete, you will see some info in the Build history

Which will look like this:

   .. code-block:: bash

       Image: ZZCI - CentOS 7 - builder - x86_64 - 20190910-180457.538

Or there is an openstack command for admins.

   .. code-block:: bash

       openstack --os-cloud ODLCI image list and grab it from there..

So you take that information and update a file in your ci-managment repo
umbreall-project/ci-management/jenkins-config/clouds/openstack/UMBRELLA-PROJECT-VEX/
for example:
centos7-builder-2c-1g.cfg

   .. code-block:: bash

       IMAGE_NAME=ZZCI - CentOS 7 - builder - 20181115-0246
       LABELS=centos7-basebuild-4c-4g
       HARDWARE_ID=v1-standard-4

In this case you would also want to update
centos7-builder-4c-4g.cfg

You replace the IMAGE_NAME with the new string we got from the ci-management-packer-merge-centos-7-builder job.
You put that up for review, and then verfiy and merge, and voila that is the current workflow.

There is room for improvement here.

Some info on the jenkins side of this about the  ci-management-packer-merge jobs:
https://docs.releng.linuxfoundation.org/projects/global-jjb/en/latest/jjb/lf-ci-jobs.html?highlight=jenkins-config#jenkins-configuration-verify

########################
Update Packer Base Image
########################
If you want to update the base image.
you need to download a .img file
convert it to raw format.

   .. code-block:: bash

       qemu-img convert -f qcow2 -O raw bionic-server-cloudimg-amd64.img bionic-server-cloudimg-amd64-raw.img

upload it to the cloud in question

   .. code-block:: bash

       openstack image create --disk-format=raw --file=bionic-server-cloudimg-amd64-raw.img 'LF - Ubuntu 18.04 LTS (2020-07-29)'

update common packer to use this new image.
eg: vars/ubuntu-18.04.json 
once that is merged tag common packer with the new version

   .. code-block:: bash

       git tag -s v0.6.2 -m  "common-packer v0.6.2 release"
       git push origin v0.6.2

pull common packer changes into global-jjb of your project

   .. code-block:: bash

       cd packer/common-packer/
       git checkout git checkout v0.6.2

once that is merged
re-run one of the packer merge jobs it will use the new base image.



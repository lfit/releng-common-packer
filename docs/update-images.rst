#####################
Update Packer Images
#####################

This is just to get my head around the current workflow.

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


So I have some questions about this...

So some projects have extra bits that they add to their packer images
Driven by changes to files in for example:

umbrella-project/ci-management/packer/templates/builder.json

So each projects image, say centos7-builder-2c-1g might be completely diffrent.

If we can share images across all umbrealla projects, could we not drive all the builds from a single place and just append the images with
the umbreall project's name, like:

acumos-centos7-builder-2c-1g.cfg
onap-centos7-builder-2c-1g.cfg

In that case we could even have a default-builder-2c-1g.cfg for an unmodified image, which would be used for 
tox verify or read the docs, simple stuff, that needs a straigforward and easy to manage builder.

we should have a straightforward way of:

mergeing a change to ansible/roles/*
it builds a new default-builder-2c-1g.cfg and spits out the 
"IMAGE_NAME=ZZCI - CentOS 7 - builder - 20181115-0246"

Then all projects could modify their umbreall-project/ci-management/jenkins-config/clouds/openstack/UMBREALL-PROJECT-VEX/default-builder-2c-1g.cfg
more easily. Or we could even automate creating a review in each umbrella projects ci-management repo, which would just need to be merged.

Some info on the jenkins side of this about the  ci-management-packer-merge jobs: 
https://docs.releng.linuxfoundation.org/projects/global-jjb/en/latest/jjb/lf-ci-jobs.html?highlight=jenkins-config#jenkins-configuration-verify

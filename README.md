SUASecLab Virtual Machines
==========================

This repository defines the virtual machines available in the SUASecLab.
The VMs are defined by using HashiCorp (packer) language and bash scripts.
You have to install [packer](https://www.packer.io/) to build them.

Procedure
---------

First the dependencies have to be downloaded:

```
./download-dependencies.sh
```

Then you can start building the VMs:

```
packer build <FILE>
```

You can change the default passwords with the following script:

````
./change_password.sh <NEW_PASSWORD>
````
Currently there are the following VMs available:

| Name        | File                | Description                                                                                  |
|-------------|---------------------|----------------------------------------------------------------------------------------------|
| iotlab      | iotlab.pkr.hcl      | Sets up a build enviroment based on Debian for Contiki-NG (Cooja simulator + RE-Mote)        |
| heaven      | heaven.pkr.hcl      | Basic VM for programming (Python, C, C++, Java, PHP) and getting familiar with GNU/Linux     |
| heaven-exam | heaven-exam.pkr.hcl | Heaven VM configured for performing exams (no networking tools, no web development)          |
| kali        | kali.pkr.hcl        | Kali Linux VM for the ethical hacking course. Set up with XFCE desktop and standard programs |
| suasploitable-basic| suasploitable-basic.pkr.hcl | A very vulnerable VM used to teach ethical hacking|
|suasploitable-cloud | suasploitable-cloud.pkr.hcl | A VM used to teach ethical hacking. Installs a cloud application (either Nextcloud or SeaFile, which one is deceided on randomly). Nextcloud randomly uses either Apache or NGINX as web server. Contains randomly selected security vulnerabilities.|
|suasploitable-cms | suasploitable-cms.pkr.hcl | A VM used to teach ethical hacking. Installs a content management system. Either Drupal or Wordpress is installed randomly, using either Apache or NGINX as web server. Contains randomly selected security vulnerabilities.|

For building the exam machine, the `pushExam.sh` file in  the `files` directory must be replaced with the correct one:

`cp ../configuration/pushExam.sh ./files/`


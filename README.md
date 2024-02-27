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

Currently there are the following VMs available:

| Name   | File           | Description                                                                               |
|--------|----------------|-------------------------------------------------------------------------------------------|
| iotlab | iotlab.pkr.hcl | Sets up a build enviroment based on Debian for Contiki-NG (Cooja simulator + RE-Mote)     |
| heaven | heaven.pkr.hcl | Basic VM for programming (Python, C, C++, Java, PHP) and getting familiar with GNU/Linux  |
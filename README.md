# Planet9
This repository contains the Planet9 release files, as well as various helper
scripts.

## Dockerfiles
This repo has two docker files - one which runs on debian, and one which runs
alpine, a smaller image optimized for containerization. Both are based of the
[official docker node images](https://github.com/nodejs/docker-node).

These are provided as a useful startout point if you would like to create your
own images.

To build the [debian based image](Dockerfile-alpine), clone this repository,
enter the directory and run:

``` shell
docker build -f Dockerfile -t YourImageName .
```

.. or for the [alpine based image](Dockerfile-alpine):

``` shell
docker build -f Dockerfile-alpine -t YourImageName .
```

If you need to include any custom npm modules in the image, create a
package.json file and add the modules to that:

``` shell
npm init -y
npm install ...
```

Once package.json exists, the additional modules will be installed to
/home/node/node_modules, as part of the build step above. These modules can then
be referenced from P9. Note that they are built inside the container itself.
This is because certain modules require a compilation step, which is dependant
on the system that P9 is running on.

Note that is important that the modules are built with the same node version P9
was built with. These images will be updated to use the same version as needed.

Once the image is built, you can run it:

``` shell
docker run -p 3000:8080 YourImageName
```

.. where 3000 is the port you want to access it by, ie http://localhost:3000.

This works fine as a simple test, but as soon as you stop the container all
modifications will be lost. This is because P9 is simply running with a local
file based database. A local file based database is not recommended for
production use either. To make permanent config changes to the container, you
need to change config/production.json - specifically the database part. The
easiest way to do this is simply to start P9 locally, to to settings, enter the
database details, verify that it works, and then copy the generated config file
to config/production.json, and then rebuild the image.

## Helper scripts
The scripts folder contains a file [linux-helper.sh](scripts/linux-helper.sh)
which can be used to install Planet9 as a systemd service. Note that this is not
necessary if you run P9 as a docker image

To run it, make sure you have both the script and planet9-linux in the same
directory, then just run it:

``` shell
sudo ./linux-helper.sh
```

Follow the help text to finish the installation.

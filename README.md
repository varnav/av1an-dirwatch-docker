[![Docker Pulls](https://img.shields.io/docker/pulls/varnav/av1an-dirwatch.svg)](https://hub.docker.com/r/varnav/av1an-dirwatch) [![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT/)

## What's this?

It will watch directory, and run [av1an](https://github.com/master-of-zen/Av1an) if it sees a file there.

## How to use

### Run interactively, watching /opt/in directory, outputting to /opt/out, using faster encoder

```sh
docker run --rm -it -v "/opt/in:/home/user/in" -v "/opt/out:/home/user/out" varnav/av1an-dirwatch -enc svt_av1 -v "-enc-mode 3" -a "-c:a libopus -b:a 96k"
```

### Run as daemon

```sh
docker run -d --name optimize-images -v "/opt/in/:/home/user/in" -v "/opt/out/:/home/user/out" --restart on-failure:10 --network none --security-opt no-new-privileges varnav/av1an-dirwatch
```

### Known issues

Will not work under WSL2 because of [this](https://github.com/microsoft/WSL/issues/4739).

### TODO

* Multistage build to make smaller image


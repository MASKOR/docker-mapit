# docker-mapit

This docker container builds and runs a [mapit](https://github.com/MASKOR/mapit) server.
You can use the master to get the newest version of mapit or one of the tags, they build and run the corresponding version of mapit.

## Build

    docker build -t mapit .

## Run

    docker run \
      -p 5555:5555 \
      -v <absolute-path-to-mapit-repo-on-host-system>/.mapit:/root/ws/mapit/build/tools/mapitd/.mapit \
      mapit

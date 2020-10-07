# usage

The repository has a `Makefile` which follows a standard target naming convention for cleaning, building, testing and packaging.
To see the various targets and supporting help text try:

```
make help
```

# Publishing Docker Image

To release a new version and publish a new docker image

* Update the version number in `build.gradle`
* Run (docker daemon must be logged into proper Docker Hub account):

```
make publish
```

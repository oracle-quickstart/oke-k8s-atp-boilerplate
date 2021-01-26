# k8s-boilerplate

This is a demo repository with a working project to showcase building a micro-services based application

## Example micro-service architecture

The core of this repository is to showcase a typical setup and workflow to develop and deploy a micro-services architecture in a kubernetes cluster.

The repository contains 3 services for demo purpose, however the tooling implemented can be re-used for any type of project.

## Repository structure

The repository has the following structure:

```
├── README.md
├── creds.env
├── creds.env.template
├── global.env
├── infrastructure
|   └──
├── k8s
│   ├── base
│   ├── build
│   └── overlays
│       ├── development
│       ├── production
│       └── staging
├── makefile
├── makefile.common
├── makefile.python
├── scripts
|   └──
└── src
    ├── consumer
    ├── producer
    └── web
```

- The `infrastructure` folder contains the `terraform` scripts to provision the credentials required to develop and deploy

    This includes:
    - an OCI user with credentials to push Docker images to a tenancy-wide OCI private registry
    - an OCI user with private key and API key to interact with an OKE cluster
    - Since the project makes use of the Streaming service, it includes a user with credentials specific to this service.

    The terraform takes an existing OKE cluster OCID and creates the users and credentials, as well as the `Secrets` in the `default` namespace. Note that to make use of these credentials in other namespaces, the secrets need to be copied to the desired namespace.

- The `k8s` folder contains the kubernetes manifests to deploy the project. It is using `kustomize` with overlays for 3 environments: `development`, `staging` and `production`.

- The `scripts` folder contains scripts used for setup and for CI

- The `src` folder contains the source code for each service. In our example, that includes 3 services `consumer`, `producer` and `web`.

    Each service folder is built into a Docker image, and includes a `makefile` with tasks for this purpose.

## Tooling

The keys functions are integrated into `makefile`s. 

### Application-wide makefile

The root folder includes a `makefile` to run application-wide functions. Run `make` on the root to get the help text:

```
help                           This help.
backup                         backup a current version to previous folder to keep a copy before build
restore                        restore a previous version to the current folder after undeploy
build                          Build kubernetes manifests with kustomize
deploy                         Build and Deploy
undeploy                       unDeploy the current stack
setup                          Setup dependencies
namespace                      create a namespace. use with NS=<namespace>
secrets                        use with NS=<namespace> :copy secrets from default to given namespace
build-all                      build all images in the project
publish-all                    publish all images in the project
release-all                    release all images in the project
install-all                    Install environments for all projects
lint-all                       Lint all python projects
set-digests                    set image digests for all services in the kustomization file
check-digests                  check that image digests in the kustomization file match latest digests
set-versions                   set image versions in the kustomization file
check-versions                 check that image digests in the kustomization file match latest digests
```

The `build` and `deploy` commands build and deploy the kubernetes manfests for a given environment, passed as `ENVIRONMENT=<environment>` (either `development` (default), `staging`, or `production`)

The tasks ending in `-all` loop through all service folders and run the corresponding command, related to the Docker image: (`build`, `publish`, `release`), the development or test environemt setup (`install`) or testing task (`lint`)

The `set-digests` and `set-versions` respectively update the image digests or version in the kubernetes manifests, which `check-digests` and `check-versions` check if the latest digests or versions matches the respective values in the kubernetes deployment manifests.

### Service specific makefile

Each service folder also includes its own `makefile` for project specific tasks. Run `make` for the help text:

```
help                           This help.
run                            Run container with env from `runtime.env`
version                        Output current version
update-version                 update the version file with new version 
image-version                  Output current image with version
build                          Build the container
build-nc                       Build the container without caching
up                             Run container on port configured in `config.env` (Alias to run)
stop                           Stop and remove a running container
repo-login                     Login to the registry
release                        Make a release by building and publishing the `{version}` ans `latest` tagged containers to registry
publish                        Publish the `{version}` ans `latest` tagged containers to ECR
publish-latest                 Publish the `latest` taged container to ECR
publish-version                Publish the `{version}` taged container to ECR
tag                            Generate container tags for the `{version}` ans `latest` tags
tag-latest                     Generate container `latest` tag
tag-version                    Generate container `{version}` tag
pull-latest                    pull latest tag
digest                         Output latest image digest (! requires published image)
digest-sha                     Output latest image digest sha (! requires published image)
set-digest                     Set the image digest for this service in the deployment
set-version                    Set the image version for this service in the deployment
install                        Setup the environment
lint                           run flake8 linter and isort imports sorter test
isort-fix                      run isort and fix issues
```

The `build` and `publish` tasks respectively build and publish the service Docker image.

The service `VERSION` is taken from the `version.txt` file located in each folder. It can be updated manually or using the `make update-version` task. 

`set-digest` and `set-version` respectively inject the latest published image digest or version into the kubernetes kustomization manifest for deployment.

## Git flow

The git flow assumed for this repository is the following:

- `master` is the production branch, and the latest release runs in the `production` kubernetes environment. 
- Production releases are tagged in the `master` branch.
- The only time master may be out-of-date with production is between merging latest bug fixes and features and cutting a new release.
- `development` is the branch where working features live. The `development` branch is deployed on a `staging` environment (and namespace) for manual and integration testing.
- Developers work on feature branches named `feature/name`. When a feature is finished, it is merged into the `development` branch. 
- Bug fixes discovered during testing on staging are branched from the `development` branch under a `bugfix/name` branch, and merged back into `development` when finished.
- Hot fixes found in production are branched from the `master` branch under a `hotfix/name` branch, and merged back into `master` and `development`
- Upon merging of one or more hot fixes, or merging the `development` branch with new features, a new release is cut ansd tagged on `master`.
- Upon release, the `master` branch code is deployed to the production kubernetes environment.

This is obviously assuming one `production` environment and one product (i.e. not a multi-platform release )

## Continuous Integration / Continuous Deployment

The repository makes use of Github Actions to test services and build images.

The automated test and build follows the git flow logic and behaves as follows:

- A Github Action runs on opening a Pull Request to the `development` branch, or on pushing to the `development` branch, so that during development on a `feature/*` branch, CI does not run, but does when a PR is opened against `development`

    This action will run the `lint` task on all services and perform some mock tests.
- 

## development flow


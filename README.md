# k8s-boilerplate

This is a demo repository with a working project to showcase building a micro-services based application

## Git flow

The assumed git flow is the following:

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
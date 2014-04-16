# hubot-pull-request [![Build Status](https://travis-ci.org/blacklane/hubot-pull-request.svg?branch=master)](https://travis-ci.org/blacklane/hubot-pull-request)

A hubot script that handles merge requests (Gitlab) and pull requests (Github).

## Tiny note

- Github is not yet fully supported.

## Features

- List all merge requests from a Gitlab server.
- List all pull requests from Github.
- Assign merge request to random developers of a Gitlab group.

## Triggers

- `hubot merge-request list <scope>`
- `hubot merge-request assign <project-identifier> <merge-request-identifier>`
- `hubot pull-request list`
- `hubot pull-request assign <project-identifier> <pull-request-identifier>`



## Installation

Add `hubot-pull-request` to your `package.json` file:

```
...
  "dependencies": {
    "hubot": ">= 2.5.1",
    "hubot-scripts": ">= 2.4.2",
    "hubot-fliptable": ">= 0.0.0"
  }
```

Add `hubot-pull-request` to your `external-scripts.json`:

```
["hubot-pull-request"]
```

Run `npm install`.

## Configuration

The plugin depends on environment variables beginning with `HUBOT_PULL_REQUEST_`.
The following configurations are available:

* `HUBOT_PULL_REQUEST_PAGINATION_BORDER`          - The maximum amount of pages. Default: 100
* `HUBOT_PULL_REQUEST_PAGINATION_PER_PAGE`        - The number of items per page. Default: 100
* `HUBOT_PULL_REQUEST_GITLAB_HOST`                - The hostname of the gitlab server.
* `HUBOT_PULL_REQUEST_GITLAB_BASIC_AUTH_USERNAME` - The username of the basic auth.
* `HUBOT_PULL_REQUEST_GITLAB_BASIC_AUTH_PASSWORD` - The password of the basic auth.
* `HUBOT_PULL_REQUEST_GITLAB_API_TOKEN`           - The api token of a gitlab user.
* `HUBOT_PULL_REQUEST_GITHUB_AUTH_USERNAME`       - The username of a github user.
* `HUBOT_PULL_REQUEST_GITHUB_AUTH_PASSWORD`       - The password of a github user.

## Look'n'Feel

### Reading merge requests:

```
sdepold:
hubot merge-request list

hubot:
@sdepold Searching for merge requests ...

hubot:
group/project-1
---------------
54 » opened » unassigned » Something awesome
65 » opened » sdepold » Pretty important change
82 » opened » someone » API extension

group/project-2
---------------
2 » opened » unassigned » Fix for ticket #1234
```

### Assigning merge requests:

```
sdepold:
hubot merge-request assign group/project-1 54

hubot:
@sdepold Assigning merge request #54 of group/project-1 ...

hubot:
Successfully assigned the merge request 'Something awesome' to mr-super-duper.
```

## Running the tests

```
npm install
npm test
```

## Development notes

In order to improve the plugin, it is quite handy to `npm link`
the plugin into your hubot instance. It's as easy as this:

```
# In the plugin directory:
npm link

# In the hubot directory:
npm link hubot-pull-request
```

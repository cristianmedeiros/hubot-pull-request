# Changelog

## v0.5.0
- `bender pr a` takes now only people into account which are online. 

## v0.4.2
- Try/catch errors
- Add urls to pr listings

## v0.4.1
- Small fixes:
  - Initializing `subscribers` in Hubot brain, so we don't have to do it manually.
  - `Subscriber.findNamesFor` performs a clone of the Hubot brain data - otherwise it would modify the persisted data (not desired).

## v0.4.0
- Added possibility to subscribe some users to a particular Github / Gitlab project. If a Github / Gitlab project has subscribers on Hubot, then pull / merge request assignments will only go to these subscribers. If no subscribers were found for a given project, Hubot will choose from all project collaborators.
  - Triggers:
    - `hubot github|gitlab subscribe <project> <user>`
    - `hubot github|gitlab s <project> <user>`
- Added possibility to unsubscribe a user from a particula Github / Gitlab project:
  - Triggers:
    - `hubot github|gitlab unsubscribe <project> <user>`
    - `hubot github|gitlab uns <project> <user>`
- Added possibility to list all subscribers:
  - Triggers:
    - `hubot github|gitlab subscribers`
    - `hubot github|gitlab sbs`
- Added possibility to store a Hubot user's Github / Gitlab user name. If a Hubot user has a Github / Gitlab user name registered with Hubot, then random pull / merge request assignments will exclude the caller.
  - Triggers:
    - `hubot github|gitlab me <user>`
- Added possibility to display the Github / Gitlab registered user for the calling Hubot user:
  - Triggers:
    - `hubot github|gitlab me`
- Subscribers can be persisted to the file system, if you enable the `file-brain.coffee` script in your `hubot-scripts.json` file.

## v0.3.0
- Added possibility to assign a pull request to a random user.
  - Triggers:
    - `hubot pull-request assign <pid> <rid>`
    - `hubot pull-request a <pid> <rid>`
    - `<pid>` => An identifier of a project á la `namespace/project-1`
    - `<rid>` => The public id of a pull request (as in the URL).

## v0.2.0

- Added possibility to list all open pull request of from github.
  - Triggers:
    - `hubot pull-request list`
    - `hubot pull-request l`
    - `hubot pr list`
    - `hubot pr l`

## v0.1.0

- Added possibility to list all merge request from a gitlab server.
  - Triggers:
    - `hubot merge-request list <scope>`
    - `hubot merge-request l <scope>`
    - `hubot mr list <scope>`
    - `hubot mr l <scope>`
    - `<scope>` => One of ['opened', 'closed', 'merged', '*']. Default: 'open'.
- Added possibility to assign a specific merge request to a random user.
  - Triggers:
    - `hubot merge-request assign <pid> <rid>`
    - `hubot merge-request a <pid> <rid>`
    - `<pid>` => An identifier of a project á la `namespace/project-1`
    - `<rid>` => The public id of a merge request (as in the URL).

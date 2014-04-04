# Changelog

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

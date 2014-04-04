# Changelog

## v0.1.0

- Added possibility to list all merge request of a gitlab server
  - Triggers:
    - `hubot merge-request list`
    - `hubot merge-request l`
    - `hubot mr list`
    - `hubot mr l`
- Added possibility to assign a specific merge request to a random user.
  - Triggers:
    - `hubot merge-request assign <pid> <rid>`
    - `hubot merge-request a <pid> <rid>`
    - `<pid>` => An identifier of a project á la `namespace/project-1`
    - `<rid>` => The public id of a merge request (as in the URL).

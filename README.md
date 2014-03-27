# hubot-pull-requests

A hubot script that handles merge requests (Gitlab) and pull requests (Github).

## Installation

Add `hubot-pull-requests` to your `package.json` file:

```
...
  "dependencies": {
    "hubot": ">= 2.5.1",
    "hubot-scripts": ">= 2.4.2",
    "hubot-fliptable": ">= 0.0.0"
  }
```

Add `hubot-pull-requests` to your `external-scripts.json`:

´´´
["hubot-pull-requests"]
´´´

Run `npm install`.

## Development notes

In order to improve the plugin, it is quite handy to `npm link`
the plugin into your hubot instance. It's as easy as this:

```
# In the plugin directory:
npm link

# In the hubot directory:
npm link hubot-pull-request
```

# hubot-pull-request

A hubot script that handles merge requests (Gitlab) and pull requests (Github).

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

The plugin depends on a environment variable called `HUBOT_PULL_REQUESTS_CONFIG`.
... TODO

## Development notes

In order to improve the plugin, it is quite handy to `npm link`
the plugin into your hubot instance. It's as easy as this:

```
# In the plugin directory:
npm link

# In the hubot directory:
npm link hubot-pull-request
```

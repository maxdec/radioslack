# RS: Radio Slack

This is a collaborative jukebox for Slack built with [Elixir](http://elixir-lang.org/).

## How it works

### Basics

This repository contains the code for a webserver that has 2 main endpoints:

- `POST /api` receives requests from Slack and allows controlling the player (starting, stopping, adding tracks)
- `GET /stream` returns an audio stream that can be opened in your media player or browser


### Slack Integration

You need to add a ["Slash Command"](https://slack.com/apps/A0F82E8CA-slash-commands) integration, with such settings:

- **Command**: `/radio`
- **URL**: `http://radio.example.com/api`
- **Method**: `POST`
- **Token**: Do not edit (but keep the value for the `SLACK_TOKEN` env var)
- **Customize Name**: `Radio`
- **Description**: `Play YouTube or SoundCloud tracks`
- **Usage Hints**: `[ status | playlist | add <url> | help ]`

### Usage

In Slack:

- `/radio status`​ - displays the player status
- `/radio playlist` - displays the tracks in the playlist
- `/radio add <url>`​ - adds a new track to the playlist (YouTube or SoundCloud links)
- `/radio start` - starts the player
- `/radio stop` - stops the player
- `/radio help` - displays the help
​

### Audio Stream

You can access the audio stream at `$HOSTNAME/stream` (`http://localhost:4000/stream` by default).  
Most the players accept to open such a stream (it works with VLC or iTunes or even in your browser).

## Getting Started

### Running the Docker Image

If you just want to run it (with production settings), use the [Docker image](https://hub.docker.com/r/maxdec/radioslack/):

```
docker run \
  -p 4000:4000 \
  -e PORT=4000 \
  -e HOSTNAME=http://example.com \
  -e SLACK_TOKEN=132456 \
  -e SOUNDCLOUD_CLIENT_ID=123456 \
  maxdec/radioslack
```

### Running the Elixir app

If you don't want to run a Docker container, you can run the elixir app.  
**That's the way to go for development.**

#### Requirements

Before running the app, make sure you have the following packages or binaries:

1. `Erlang/OTP` and `Elixir` (obviously)

    Check [http://elixir-lang.org/install.html](http://elixir-lang.org/install.html)

2. [`ffmpeg`](http://ffmpeg.org) for audio transcoding

    Please refer to the [download page](http://ffmpeg.org/download.html) and follow the instructions for your OS.  
    Example: `sudo apt-get install ffmpeg`

3. [`goon`](https://github.com/alco/goon) (for [Porcelain](https://github.com/alco/porcelain))

    Download the binary from the [releases page](https://github.com/alco/goon/releases) and put it somewhere in your `$PATH` (e.g. in `/usr/local/bin`)

#### Installation

```
$ git clone https://github.com/maxdec/radioslack
$ cd radioslack
$ mix deps.get compile
$ SLACK_TOKEN=123 SOUNDCLOUD_CLIENT_ID=456 mix run --no-halt
```

Now you have the radio server running at [http://localhost:4000](http://localhost:4000).

### Environment Variables

You can configure the following environment variables:

```
PORT - Port for the server (Default: "4000")
HOSTNAME - The hostname to display in the links (Defaults: "http://localhost:4000")
SLACK_TOKEN - The verification token that is sent by Slack "Slash Commands" (Defaults: "123")
SOUNDCOUD_CLIENT_ID - SoundCloud API Client ID, required for SouldCloud tracks (Defaults: nil)
```

/!\ Those variables need to be set at compile time (not runtime).

## ToDos

- Improve support for YouTube protected videos ([youtube-dl](https://github.com/rg3/youtube-dl)?)
- Improve Slack messages
- Add "voting" feature to skip the current track
- Add on-disk persistence for the playlist (so it can be restored after restarting the app)
- Add history (past tracks)
- Add support for playlists (YouTube or SoundCloud)

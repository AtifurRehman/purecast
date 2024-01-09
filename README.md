# PureCast: A Dart Package for Chromecast Integration

Welcome to **PureCast**, a pure Dart package designed for seamless discovery, connection, and video playback on Chromecast devices.

This package is inspired by and based on the foundational work available at [terrabythia/dart_chromecast](https://github.com/terrabythia/dart_chromecast). Further modifications are based of [vitalidze/chromecast-java-api-v2](https://github.com/vitalidze/chromecast-java-api-v2)

---

## Features

- **Device Discovery**: Locate your Chromecast device within your network.
- **Connectivity**: Establish a connection to your Chromecast effortlessly.
- **Video Playback**: Stream and control video playback on your Chromecast device.

---

# Quick Example: Using PureCast

This guide focuses on a basic usage of key classes from the PureCast package in Dart for Chromecast device integration.
This library is still a work in progress. The API is **not stable**, the quality is low and there are a lot of bugs.
Please see the example app for a complete CLI example.

## Step 1: Create a Cast Media Object

Convert each media URL into a `CastMedia` instance. These instances represent the media you wish to cast.

```dart
CastMediaMetadata metadata = CastMediaMetadata(title: "Loading Title Metadata");
CastMedia media = CastMedia(url: "http://commondatastorage.googleapis.com/gtv-videos-bucket/big_buck_bunny_1080p.mp4", metadata:metadata);
```

## Step 2: Specify Chromecast Device

Search for available Chromecast devices on the network using [multicast DNS](https://github.com/flutter/packages/tree/main/packages/multicast_dns) :

```dart
List<CastDevice> devices = await PureCast.searchDevices();
```

Or directly specify a device/service:

```dart
CastDevice device =
        await CastDevice.create(host: host, port: port, type: '_googlecast._tcp');
```

## Step 3: Instantiate the Cast Sender Class and start the connection

After instanciating the CastDevice instance, instantiate the CastSender object, responsible for controlling and listening for cast session updates

```dart
CastSender castSender = CastSender(
    device,
  );
bool connected = await castSender.connect();
```

## Step 4: Load CastMedia playlist

Now, you can use your CastSender to load a CastMedia, or multiple ones, and send it to the Chromecast

```dart
castSender.load(media);
castSender.loadPlaylist(mediaPlaylist);
```

---

# Documentation

## CastSender Class

### Methods

The `CastSender` class in the PureCast package is a comprehensive tool for interacting with a Chromecast device. Here's a breakdown of its methods:

1. **connect():** Establishes a connection to the Chromecast device. It creates a new session, sets up various channels and initiates the connection process.

2. **reconnect():** Attempts to reconnect to an existing Chromecast session using provided source and destination IDs. It re-establishes the media channel and checks for media status to confirm successful reconnection.

3. **disconnect():** Disconnects from the Chromecast device. It sends a close message to the connection channel and cleans up resources.

4. **launch():** Launches an application on the Chromecast device, defaulting to the default media receiver app if no specific app ID is provided.

5. **load():** Loads a single `CastMedia` item for casting. It can force the next item in the queue to play immediately.

6. **loadPlaylist():** Loads a playlist of `CastMedia` items. It supports appending to the current queue and optionally forcing the next item to play.

7. **play():** Sends a play command to the currently active media session.

8. **pause():** Sends a pause command to the currently active media session.

9. **togglePause():** Toggles between play and pause based on the current state of the media.

10. **stop():** Stops the playback of the currently active media session.

11. **seek():** Seeks the current media playback to the specified time.

12. **setVolume():** Sets the volume of the Chromecast device to the specified level, ensuring it doesn't exceed the maximum limit.

13. **get castSession:** Getter for the current `CastSession`.

14. **setPlayBackRate()** Setter for the playback rate of the current playing `CastMedia`.

15. **setTrackId()** Setter for the current trackId.

16. **clearTrackId()** Clears the current trackId.

### Stream Controllers

This class also includes two public `StreamController` objects. These controllers are used for broadcasting updates about the Chromecast session and media status to any listeners that may be interested in these events.

1. **castSessionController (`StreamController<CastSession?>`):**

   - This `StreamController` broadcasts updates regarding the Chromecast session.
   - Listeners to this stream receive updates on the state of the Chromecast session, such as when it connects, disconnects, or undergoes significant changes.

2. **castMediaStatusController (`StreamController<CastMediaStatus?>`):**
   - This `StreamController` focuses on broadcasting updates about the media status.
   - It provides listeners with information about the current media being played on the Chromecast device, including playback status (like playing, paused, or stopped), volume changes, and other relevant media updates.

These enable real-time monitoring and responsive interaction with the Chromecast session and media playback status.

---

## _Example_ Folder Usage Instructions

### Options

- **media**: A space-separated list of one or more media source URLs.
- **host** (optional): The IP address of a Chromecast device on your network.
- **port** (optional): The Chromecast device's port, defaulting to `8009`.

### Flags

- **--append** (-a): Append media to the current playlist instead of replacing it. Default: `false`.
- **--debug** (-d): Display all information logs. Default: `false`.

### Command Structure

```
dart example/index.dart <media> [--host <host> [--port <port> [--append [ --debug]]]]
```

### Playback Control

Control the playback using the following keyboard shortcuts:

- `space`: Toggle pause/play.
- `s`: Stop playback.
- `Esc`: Disconnect from the device.
- `Left Arrow`: Seek backward by 10 seconds.
- `Right Arrow`: Seek forward by 10 seconds.

### Sample Command

To play a sample video:

```
dart example/index.dart http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4
```

### Reconnecting to an Active Session

If you exit the command line without disconnecting, the video will continue playing. To reconnect without altering the current playlist:

```
dart index.dart --host=192.168.1.1
```

---

## Contribution

Feel free to [file an issue](https://github.com/bariccattion/purecast/issues/new) if you find a problem or [make pull requests](https://github.com/bariccattion/purecast/pulls).

All contributions are more then welcome.

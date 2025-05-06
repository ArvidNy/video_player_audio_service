# video_player_audio_service

This project demonstrates an example implementation of the Flutter `audio_service` package with `video_player` to provide background audio playback functionality for videos.

## Overview

The project shows how to:
- Use `audio_service` to handle audio playback in the background
- Integrate with `video_player` for video content
- Maintain audio playback when the app is in the background

## Dependencies

Currently, this project uses a forked version of the `video_player` package until a pull request is merged into the main repository. The fork includes necessary functionality for proper integration with `audio_service`.

## Behavior on iOS

On iOS, video playback pauses when the screen is turned off but can be resumed via the notification controls. Audio files, however, continue playing without interruption when the screen is turned off.

## Getting Started

1. Clone this repository
2. Run `flutter pub get` to install dependencies
3. Run the app on your preferred device

## Note

Once the pull request for the `video_player` package is merged, this project will be updated to use the official package version.

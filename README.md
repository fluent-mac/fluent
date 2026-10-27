# Fluent

Fluent is a Mac app I made for getting better with the keyboard, the mouse and the trackpad. It also has a checklist for looking over a used Mac before you buy it.

Site: https://fluent-mac.github.io

![Fluent on a Mac](https://fluent-mac.github.io/media/home.png)

## What's in it

- **Typing practice.** Timed tests, word counts, phrases or text you paste in. It keeps track of the keys you miss or hit slowly and gives you drills for them. There's a key map, progress charts and a ghost that races your best run.
- **Click, reaction and aim tests.** Plain tests for how fast you click, how quickly you react and how well you aim. There are also pages for checking your mouse and keyboard.
- **Trackpad and shortcut lessons.** Walks you through gestures and shortcuts one at a time. You pass a lesson by doing it for real.
- **Mac Check.** Hardware info, a trackpad test, dead pixel patterns and speaker, microphone and camera tests, for when you're looking at a used Mac.
- **Input settings.** Key repeat, tracking speed and scrolling in one place, with links to the right System Settings panes.

## Install

Download the latest `Fluent.dmg` from [Releases](https://github.com/fluent-mac/fluent/releases/latest), open it and drag Fluent to Applications. You need macOS 26 or later.

The app isn't signed or notarized yet, because that needs a paid Apple developer account. If macOS says it can't verify Fluent, open System Settings, go to Privacy & Security and click Open Anyway.

## Privacy

Fluent doesn't use the network at all. Your results are saved on your Mac in `~/Library/Application Support`. The camera and microphone are only used on the Mac Check pages, when you ask for them, to show a preview and a level meter. Nothing is recorded or sent anywhere.

The source is all here, so you can check that yourself.

## Build it yourself

You need a Mac with Xcode 26.

```sh
swift test            # run the tests
./Scripts/bundle.sh   # builds build/Fluent.app and build/Fluent.dmg
```

The code is SwiftUI. `Sources/FluentCore` holds the logic that doesn't depend on the UI (lessons, shortcuts, key layouts, word lists) and has tests. `Sources/Fluent` is the app.

## License

Apache License 2.0, the same license Apple uses for Swift. See [LICENSE](LICENSE).

## Made by

texivi. I write about what I'm working on at [texivi.github.io](https://texivi.github.io).

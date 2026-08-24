import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

Item {
  id: root

  property var settings: ({})

  property var events: []
  property var buckets: ({})
  property var feeds: []
  property bool configured: false
  property bool stale: false
  property string error: ""
  property var generatedAt: null
  property bool syncing: syncProcess.running || feedProcess.running
  property bool everLoaded: false

  readonly property string feedError: Model.firstFeedError(feeds)

  readonly property int refreshIntervalSec: intSetting("refreshIntervalSec", 900, 60, 86400)
  readonly property int dayStartHour: intSetting("dayStartHour", 7, 0, 23)
  readonly property int dayEndHour: Math.max(dayStartHour + 1, intSetting("dayEndHour", 22, 1, 24))
  readonly property string feedsFile: stringSetting("feedsFile", "")
  readonly property bool notificationsEnabled: boolSetting("notificationsEnabled", true)
  readonly property bool notificationSoundEnabled: boolSetting("notificationSoundEnabled", true)
  readonly property string notificationSound: normalizedSound(stringSetting("notificationSound", "Alarm"))
  readonly property int reminderMinutes: intSetting("reminderMinutes", 60, 1, 10080)
  readonly property var reminderOverrides: settings && settings.reminderOverrides
    ? settings.reminderOverrides : ({})
  property var firedReminders: ({})
  property var testEvent: null

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
  readonly property date now: clock.date
  readonly property string todayKey: Model.keyForDate(now)

  readonly property var nextEvent: Model.nextUpcoming(events, now)
  readonly property string nextRelative: Model.relativeLabel(nextEvent, now)
  readonly property var todayEvents: Model.eventsOn(buckets, todayKey)

  function scriptPath(name) {
    return String(Qt.resolvedUrl("bin/" + name)).replace(/^file:\/\//, "")
  }

  function assetPath(name) {
    return String(Qt.resolvedUrl("assets/" + name)).replace(/^file:\/\//, "")
  }

  function intSetting(name, fallback, min, max) {
    var v = parseInt(settings ? settings[name] : undefined, 10)
    if (isNaN(v)) return fallback
    return Math.max(min, Math.min(max, v))
  }

  function stringSetting(name, fallback) {
    var v = settings ? settings[name] : undefined
    if (v === undefined || v === null) return fallback
    return String(v)
  }

  function boolSetting(name, fallback) {
    var v = settings ? settings[name] : undefined
    if (v === undefined || v === null) return fallback
    return v === true || String(v).toLowerCase() === "true" || String(v) === "1"
  }

  function normalizedSound(value) {
    var sounds = { "Gentle": true, "Bell": true, "Chime": true, "Alarm": true }
    return sounds[value] ? value : "Alarm"
  }

  function soundId(value) {
    var sounds = {
      "Gentle": "message-new-instant",
      "Bell": "bell",
      "Chime": "complete",
      "Alarm": "alarm-clock-elapsed"
    }
    return sounds[normalizedSound(value)]
  }

  function previewSound(value) {
    Quickshell.execDetached(["canberra-gtk-play", "--id", soundId(value),
      "--description", "Proton Calendar reminder"])
  }

  function checkReminders() {
    if (!notificationsEnabled || !events) return
    var stamp = now.getTime()
    for (var i = 0; i < events.length; i++) {
      var event = events[i]
      if (!event || event.cancelled || event.allDay || event.startMs <= stamp) continue
      var minutes = event === testEvent ? 1
        : Model.reminderMinutes(event, reminderOverrides, reminderMinutes)
      if (minutes < 0) continue
      var target = event.startMs - minutes * 60000
      if (stamp < target || stamp >= target + 300000) continue
      var key = Model.reminderKey(event) + ":" + minutes
      if (firedReminders[key]) continue
      var next = {}
      for (var existing in firedReminders) next[existing] = firedReminders[existing]
      next[key] = true
      firedReminders = next
      var when = Qt.formatDateTime(event.start, "HH:mm")
      var body = "Starts at " + when + (event.location ? " · " + event.location : "")
      Quickshell.execDetached(["notify-send", "--app-name=Proton Calendar",
        "--icon=" + assetPath("proton-calendar.svg"), event.title, body])
      if (notificationSoundEnabled)
        previewSound(notificationSound)
    }
  }

  function scheduleTestReminder() {
    var start = new Date(now.getTime() + 120000)
    start.setSeconds(0, 0)
    var end = new Date(start.getTime() + 1800000)
    root.testEvent = Model.parseEvent({
      uid: "protoncalendar-notification-test-" + start.getTime(),
      title: "Proton Calendar test",
      location: "Notification test",
      start: start.toISOString(),
      end: end.toISOString(),
      allDay: false
    })
    var nextEvents = events.slice()
    nextEvents.push(root.testEvent)
    nextEvents.sort(function (a, b) { return a.startMs - b.startMs })
    root.events = nextEvents
    root.buckets = Model.bucketByDay(nextEvents)
  }

  function syncArgs(extra) {
    var args = ["python3", scriptPath("protoncal-sync")]
    if (feedsFile !== "") args = args.concat(["--feeds", feedsFile])
    return extra ? args.concat(extra) : args
  }

  function apply(text) {
    var state = Model.readPayload(text)
    var appliedEvents = state.events
    if (testEvent && testEvent.endMs > now.getTime()) {
      appliedEvents = state.events.slice()
      appliedEvents.push(testEvent)
      appliedEvents.sort(function (a, b) { return a.startMs - b.startMs })
    }
    root.events = appliedEvents
    root.buckets = Model.bucketByDay(appliedEvents)
    root.feeds = state.feeds
    root.configured = state.configured
    root.stale = state.stale
    root.error = state.error
    root.generatedAt = state.generatedAt
    root.everLoaded = true
    Qt.callLater(root.checkReminders)
  }

  function refresh() {
    if (syncProcess.running) return
    syncProcess.command = syncArgs(null)
    syncProcess.running = true
  }

  function ensureFresh() {
    if (!everLoaded) { loadCached(); return }
    if (!generatedAt) { refresh(); return }
    var age = (now.getTime() - generatedAt.getTime()) / 1000
    if (age >= refreshIntervalSec) refresh()
  }

  function loadCached() {
    if (cacheProcess.running) return
    cacheProcess.command = syncArgs(["--cached"])
    cacheProcess.running = true
  }

  function addFeed(url, name) {
    var trimmed = String(url || "").replace(/^\s+|\s+$/g, "")
    if (trimmed === "" || feedProcess.running) return
    feedProcess.environment = { "PROTONCAL_FEED_URL": trimmed }
    feedProcess.command = syncArgs(["--add-feed-env", "--name", String(name || "")])
    feedProcess.running = true
  }

  function removeFeed(url) {
    if (feedProcess.running) return
    feedProcess.environment = { "PROTONCAL_FEED_URL": String(url) }
    feedProcess.command = syncArgs(["--remove-feed-env"])
    feedProcess.running = true
  }

  function openDay(dateKey, title, time, view) {
    var args = [scriptPath("protoncal-open"), "--view", String(view || "week")]
    if (dateKey) args = args.concat(["--date", String(dateKey)])
    if (title) args = args.concat(["--title", String(title)])
    if (time) args = args.concat(["--time", String(time)])
    Quickshell.execDetached(args)
  }

  Process {
    id: syncProcess
    command: []
    stdout: StdioCollector { id: syncStdout; waitForEnd: true }
    onExited: function (exitCode) {
      if (exitCode === 0) root.apply(String(syncStdout.text || ""))
      else root.error = "sync failed (exit " + exitCode + ")"
    }
  }

  Process {
    id: cacheProcess
    command: []
    stdout: StdioCollector { id: cacheStdout; waitForEnd: true }
    onExited: function (exitCode) {
      if (exitCode === 0) root.apply(String(cacheStdout.text || ""))
      root.everLoaded = true
    }
  }

  Process {
    id: feedProcess
    command: []
    stdout: StdioCollector { id: feedStdout; waitForEnd: true }
    onExited: function (exitCode) {
      if (exitCode === 0) root.apply(String(feedStdout.text || ""))
    }
  }

  Timer {
    id: refreshTimer
    interval: root.refreshIntervalSec * 1000
    repeat: true
    running: true
    onTriggered: root.refresh()
  }

  Timer {
    interval: 30000
    repeat: true
    running: true
    onTriggered: root.checkReminders()
  }

  Component.onCompleted: {
    loadCached()
    firstSync.start()
  }

  Timer {
    id: firstSync
    interval: 1200
    repeat: false
    onTriggered: root.refresh()
  }
}

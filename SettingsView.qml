import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property bool notificationsEnabled: true
  property bool notificationSoundEnabled: true
  property string notificationSound: "Alarm"
  property int reminderMinutes: 60
  property int weekStart: 0
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  signal settingsRequested(bool enabled, bool soundEnabled, string sound, int minutes)
  signal weekStartRequested(int day)
  signal soundPreviewRequested(string sound)
  signal testRequested()

  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property real labelWidth: Style.space(112)
  readonly property real controlHeight: Style.space(32)

  implicitHeight: column.implicitHeight

  function save(enabled, soundEnabled, sound, minutes) {
    root.settingsRequested(enabled, soundEnabled, sound,
      Math.max(1, Math.min(10080, minutes)))
  }

  function applyMinutes(value) {
    var parsed = parseInt(value, 10)
    if (!isNaN(parsed)) save(root.notificationsEnabled,
      root.notificationSoundEnabled, root.notificationSound, parsed)
  }

  Column {
    id: column
    width: parent.width
    spacing: Style.space(7)

    PanelSectionHeader {
      width: parent.width
      text: "CALENDAR"
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    Row {
      width: parent.width
      height: root.controlHeight
      spacing: Style.space(6)

      Text {
        width: root.labelWidth
        anchors.verticalCenter: parent.verticalCenter
        text: "WEEK STARTS"
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      ButtonGroup {
        width: parent.width - root.labelWidth - Style.space(6)
        options: ["Sunday", "Monday"]
        value: root.weekStart === 1 ? "Monday" : "Sunday"
        foreground: root.foreground
        background: Color.background
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onChanged: function (value) {
          root.weekStartRequested(value === "Monday" ? 1 : 0)
        }
      }
    }

    PanelSectionHeader {
      width: parent.width
      text: "NOTIFICATIONS"
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    Row {
      width: parent.width
      height: root.controlHeight
      spacing: Style.space(6)

      Button {
        width: (parent.width - Style.space(6)) / 2
        height: root.controlHeight
        text: root.notificationsEnabled ? "Notifications on" : "Notifications off"
        iconText: root.notificationsEnabled ? "󰂞" : "󰂛"
        selected: root.notificationsEnabled
        bordered: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onClicked: root.save(!root.notificationsEnabled,
          root.notificationSoundEnabled, root.notificationSound, root.reminderMinutes)
      }

      Button {
        width: (parent.width - Style.space(6)) / 2
        height: root.controlHeight
        text: root.notificationSoundEnabled ? "Alarm sound on" : "Alarm sound off"
        iconText: root.notificationSoundEnabled ? "󰕾" : "󰝟"
        selected: root.notificationSoundEnabled
        bordered: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onClicked: root.save(root.notificationsEnabled,
          !root.notificationSoundEnabled, root.notificationSound, root.reminderMinutes)
      }
    }

    Row {
      width: parent.width
      height: root.controlHeight
      spacing: Style.space(6)

      Text {
        width: root.labelWidth
        anchors.verticalCenter: parent.verticalCenter
        text: "REMIND BEFORE"
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      ButtonGroup {
        width: parent.width - root.labelWidth - Style.space(6)
        options: ["15 min", "30 min", "1 hour", "2 hours"]
        value: root.reminderMinutes === 15 ? "15 min"
          : root.reminderMinutes === 30 ? "30 min"
          : root.reminderMinutes === 60 ? "1 hour"
          : root.reminderMinutes === 120 ? "2 hours" : ""
        foreground: root.foreground
        background: Color.background
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onChanged: function (value) {
          var values = { "15 min": 15, "30 min": 30, "1 hour": 60, "2 hours": 120 }
          if (values[value]) root.save(root.notificationsEnabled,
            root.notificationSoundEnabled, root.notificationSound, values[value])
        }
      }
    }

    Row {
      width: parent.width
      height: root.controlHeight
      spacing: Style.space(6)

      Text {
        width: root.labelWidth
        anchors.verticalCenter: parent.verticalCenter
        text: "CUSTOM"
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      TextField {
        id: minutesField
        width: Style.space(90)
        height: root.controlHeight
        placeholderText: String(root.reminderMinutes)
        inputMethodHints: Qt.ImhDigitsOnly
        foreground: root.foreground
        font.family: root.fontFamily
        Keys.onReturnPressed: root.applyMinutes(text)
        Keys.onEnterPressed: root.applyMinutes(text)
      }

      Button {
        height: root.controlHeight
        text: "Set minutes"
        bordered: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onClicked: root.applyMinutes(minutesField.text)
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.reminderMinutes + " min before"
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }

    Row {
      width: parent.width
      height: root.controlHeight
      spacing: Style.space(6)

      Text {
        width: root.labelWidth
        anchors.verticalCenter: parent.verticalCenter
        text: "ALARM SOUND"
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      ButtonGroup {
        width: parent.width - root.labelWidth - testButton.width - Style.space(12)
        options: ["Gentle", "Bell", "Chime", "Alarm"]
        value: root.notificationSound
        foreground: root.foreground
        background: Color.background
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onChanged: function (value) {
          root.save(root.notificationsEnabled, root.notificationSoundEnabled,
            value, root.reminderMinutes)
          root.soundPreviewRequested(value)
        }
      }

      Button {
        id: testButton
        height: root.controlHeight
        text: "Test in 1 minute"
        iconText: "󰂞"
        bordered: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onClicked: root.testRequested()
      }
    }

    Text {
      width: parent.width
      text: "Timed events inherit this default. Use the bell on an event to choose a different time or turn that reminder off. All-day events do not send notifications."
      wrapMode: Text.WordWrap
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }
}

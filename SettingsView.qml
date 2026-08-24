import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property bool notificationsEnabled: true
  property int reminderMinutes: 60
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  signal settingsRequested(bool enabled, int minutes)
  signal testRequested()

  readonly property color dim: Qt.darker(foreground, 1.55)

  implicitHeight: column.implicitHeight

  function applyMinutes(value) {
    var parsed = parseInt(value, 10)
    if (isNaN(parsed)) return
    root.settingsRequested(enabledButton.checked, Math.max(1, Math.min(10080, parsed)))
  }

  Column {
    id: column
    width: parent.width
    spacing: Style.space(8)

    PanelSectionHeader {
      width: parent.width
      text: "NOTIFICATIONS"
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    Row {
      width: parent.width
      spacing: Style.space(6)

      Button {
        id: enabledButton
        property bool checked: root.notificationsEnabled
        text: checked ? "Notifications on" : "Notifications off"
        iconText: checked ? "󰂞" : "󰂛"
        selected: checked
        bordered: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.settingsRequested(!checked, root.reminderMinutes)
      }

      ButtonGroup {
        width: parent.width - enabledButton.width - Style.space(6)
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
          if (values[value]) root.settingsRequested(root.notificationsEnabled, values[value])
        }
      }
    }

    Row {
      width: parent.width
      spacing: Style.space(6)

      TextField {
        id: minutesField
        width: Style.space(92)
        placeholderText: String(root.reminderMinutes)
        inputMethodHints: Qt.ImhDigitsOnly
        foreground: root.foreground
        font.family: root.fontFamily
        Keys.onReturnPressed: root.applyMinutes(text)
        Keys.onEnterPressed: root.applyMinutes(text)
      }

      Button {
        text: "Set minutes"
        bordered: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onClicked: root.applyMinutes(minutesField.text)
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.reminderMinutes + " minutes before each timed event"
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

    }

    Button {
      text: "Test in 1 minute"
      iconText: "󰂞"
      bordered: true
      foreground: root.foreground
      fontFamily: root.fontFamily
      fontSize: Style.font.caption
      onClicked: root.testRequested()
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

import QtQuick
import qs.Commons
import qs.Ui

Rectangle {
  id: root

  property var event: null
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  property bool showDate: false
  property int reminderMinutes: 60
  property bool reminderInherited: true
  property bool reminderOff: false
  property bool reminderEditorOpen: false

  signal activated()
  signal reminderChanged(var event, var value)

  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property color accentColor: event && event.color !== "" ? event.color : Color.accent

  readonly property real timeColumn: Style.space(showDate ? 132 : 52)
  readonly property real baseHeight: Math.max(Style.space(26), label.implicitHeight + Style.space(8))

  height: baseHeight
    + (reminderEditorOpen ? reminderEditor.implicitHeight + Style.space(5) : 0)
  radius: Style.cornerRadius
  color: mouse.containsMouse
    ? Style.hoverFillFor(foreground, Color.accent)
    : "transparent"

  function setReminder(value) {
    root.reminderChanged(root.event, value)
    root.reminderEditorOpen = false
  }

  Rectangle {
    id: stripe
    y: (root.baseHeight - height) / 2
    x: Style.space(6)
    width: Style.space(3)
    height: root.baseHeight - Style.space(9)
    radius: width / 2
    color: root.accentColor
    opacity: root.event && root.event.cancelled ? 0.35 : 1.0
  }

  Text {
    id: time
    y: (root.baseHeight - height) / 2
    anchors.left: stripe.right
    anchors.leftMargin: Style.space(8)
    width: root.timeColumn
    horizontalAlignment: Text.AlignLeft
    text: {
      if (!root.event) return ""
      if (root.event.allDay) {
        if (!root.showDate) return "all day"
        var from = Qt.formatDate(root.event.start, "ddd d MMM")
        if (!root.event.multiDay) return from
        var sameMonth = root.event.start.getMonth() === root.event.lastDate.getMonth()
        return Qt.formatDate(root.event.start, sameMonth ? "ddd d" : "ddd d MMM")
          + "–" + Qt.formatDate(root.event.lastDate, "ddd d MMM")
      }
      var clock = Qt.formatDateTime(root.event.start, "HH:mm")
      return root.showDate
        ? Qt.formatDate(root.event.start, "ddd d MMM") + " " + clock
        : clock
    }
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    elide: Text.ElideRight
  }

  Column {
    id: label
    y: (root.baseHeight - height) / 2
    anchors.left: time.right
    anchors.leftMargin: Style.space(8)
    anchors.right: reminderButton.left
    anchors.rightMargin: Style.space(5)
    spacing: Style.space(1)

    Text {
      width: parent.width
      textFormat: Text.PlainText
      text: root.event ? root.event.title : ""
      color: mouse.containsMouse
        ? Style.hoverStateColor(root.foreground, Color.accent)
        : root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.strikeout: root.event ? root.event.cancelled : false
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      textFormat: Text.PlainText
      visible: root.event && root.event.location !== ""
      text: root.event ? root.event.location : ""
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
    }
  }

  PanelActionButton {
    id: reminderButton
    anchors.right: parent.right
    anchors.rightMargin: Style.space(4)
    anchors.top: parent.top
    anchors.topMargin: Style.space(2)
    visible: root.event && !root.event.allDay && !root.event.cancelled
    iconText: root.reminderOff ? "󰂛" : "󰂞"
    bordered: root.reminderEditorOpen || !root.reminderInherited
    tooltipText: root.reminderOff ? "Reminder off"
      : (root.reminderInherited ? "Reminder: default (" : "Reminder: ")
        + root.reminderMinutes + " min before"
    foreground: root.reminderOff ? root.dim : root.foreground
    fontFamily: root.fontFamily
    onClicked: root.reminderEditorOpen = !root.reminderEditorOpen
  }

  Row {
    id: reminderEditor
    anchors.left: time.left
    anchors.right: parent.right
    anchors.rightMargin: Style.space(5)
    anchors.bottom: parent.bottom
    visible: root.reminderEditorOpen
    spacing: Style.space(5)

    TextField {
      id: reminderField
      width: Style.space(72)
      placeholderText: String(root.reminderMinutes)
      inputMethodHints: Qt.ImhDigitsOnly
      foreground: root.foreground
      font.family: root.fontFamily
      Keys.onReturnPressed: saveReminder.clicked()
      Keys.onEnterPressed: saveReminder.clicked()
    }

    Button {
      id: saveReminder
      text: "Set minutes"
      bordered: true
      foreground: root.foreground
      fontFamily: root.fontFamily
      fontSize: Style.font.caption
      onClicked: {
        var value = parseInt(reminderField.text, 10)
        if (!isNaN(value)) root.setReminder(Math.max(1, Math.min(10080, value)))
      }
    }

    Button {
      text: "Use default"
      selected: root.reminderInherited
      bordered: true
      foreground: root.foreground
      fontFamily: root.fontFamily
      fontSize: Style.font.caption
      onClicked: root.setReminder(null)
    }

    Button {
      text: "Off"
      selected: root.reminderOff
      bordered: true
      foreground: root.foreground
      fontFamily: root.fontFamily
      fontSize: Style.font.caption
      onClicked: root.setReminder(false)
    }
  }

  MouseArea {
    id: mouse
    anchors.left: parent.left
    anchors.right: reminderButton.visible ? reminderButton.left : parent.right
    anchors.top: parent.top
    height: root.baseHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.activated()

    PanelToolTip {
      visible: mouse.containsMouse && root.event && root.event.description !== ""
      text: root.event ? root.event.description : ""
      fontFamily: root.fontFamily
    }
  }
}

// The same bar as almide-shell's, in Quickshell (QML) — the baseline the
// modification benchmark compares against. Workspaces from Hyprland (a click
// switches), a clock, the default output's volume and the battery.
//
//   quickshell -p shell.qml

import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

ShellRoot {
  id: root

  // Theme: the values almide-shell's config.almd uses.
  readonly property int barHeight: 30
  readonly property int fontSize: 14
  readonly property color background: "#1a1b26"
  readonly property color foreground: "#c0caf5"
  readonly property color dim: "#565f89"
  readonly property color accent: "#7aa2f7"
  readonly property int padding: 12
  readonly property int gap: 16

  // Keep the default output bound, so its volume is live.
  PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

  SystemClock { id: clock; precision: SystemClock.Minutes }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData
      anchors { top: true; left: true; right: true }
      implicitHeight: root.barHeight
      color: root.background

      // Left: workspaces.
      RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: root.padding
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
          model: Hyprland.workspaces

          Rectangle {
            required property var modelData
            readonly property bool active: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData.id
            implicitWidth: label.implicitWidth + 16
            implicitHeight: root.barHeight - 8
            radius: 6
            color: active ? "#f7768e" : "transparent"

            Text {
              id: label
              anchors.centerIn: parent
              text: modelData.name !== "" ? modelData.name : modelData.id
              color: parent.active ? root.background : root.foreground
              font.pixelSize: root.fontSize
            }

            MouseArea {
              anchors.fill: parent
              onClicked: Hyprland.dispatch("workspace " + parent.modelData.id)
            }
          }
        }
      }

      // Centre: the clock.
      Text {
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "ddd MMM dd  hh:mm")
        color: root.foreground
        font.pixelSize: root.fontSize
      }

      // Right: volume, battery.
      RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: root.padding
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.gap

        Text {
          readonly property var sink: Pipewire.defaultAudioSink
          visible: sink !== null && sink.audio !== null
          text: !visible ? "" : sink.audio.muted ? "vol muted" : "vol " + Math.round(sink.audio.volume * 100) + "%"
          color: visible && sink.audio.muted ? root.dim : root.foreground
          font.pixelSize: root.fontSize
        }

        Text {
          readonly property var battery: UPower.displayDevice
          readonly property bool charging: battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged
          readonly property int percent: Math.round(battery.percentage * 100)
          visible: battery.ready && battery.isLaptopBattery
          text: (charging ? "+" : "") + percent + "%"
          color: percent <= 15 && !charging ? root.accent : root.foreground
          font.pixelSize: root.fontSize
        }
      }
    }
  }
}

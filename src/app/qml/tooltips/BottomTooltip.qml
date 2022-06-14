import QtQuick 2.4
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3

import "template" as Template

Template.Tooltip {
    id: bottomTooltip

    property var message

    anchors.bottom: parent.bottom
    Rectangle {
        anchors.fill: parent
        color: theme.palette.normal.background
        border.width: 1
        border.color: theme.palette.normal.base
        Text {
            anchors.centerIn: parent
            color: theme.palette.normal.backgroundText
            text: message
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
    }
}

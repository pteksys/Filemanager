import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

import "template" as Template

Template.Tooltip {
    id: bottomTooltip

    property var message

    anchors.bottom: parent.bottom

    Text { // or Text
        anchors.centerIn: parent
        text: message
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }
}

/*
 * Copyright (C) 2017 Stefano Verzegnassi
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License 3 as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see http://www.gnu.org/licenses/.
 */

import QtQuick 2.4
import Lomiri.Components 1.3
import QtQuick.Layouts 1.1

Item {
    property alias text: label.text

    height: units.gu(4)

    RowLayout {
        anchors {
            left: parent.left;
            right: parent.right
            verticalCenter: parent.verticalCenter
        }

        spacing: units.gu(2)

        Label {
            id: label
            Layout.alignment: Qt.AlignVCenter
            textSize: Label.Small
            color: "white"
        }
    }
}

/*
 * Copyright (C) 2013 Canonical Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Arto Jalkanen <ajalkane@gmail.com>
 */
import QtQuick 2.0
import Ubuntu.Components 0.1
import org.nemomobile.folderlistmodel 1.0

/*!
    \brief MainView with Tabs element.
           First Tab has a single Label and
           second Tab has a single ToolbarAction.
*/

MainView {
    id: root
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "filemanager"
    applicationName: "ubuntu-filemanager-app"
    
    width: units.gu(50)
    height: units.gu(75)

    property string homeFolder: "~"

    function goHome() {
        // FIXME: Get the user's home folder without requiring an instance
        // of a FolderListModel
        goTo(root.homeFolder)
    }

    function goTo(location) {
        folderPage.folder = location
    }

    function folderName(folder) {
        if (folder === root.homeFolder) {
            return i18n.tr("Home")
        } else if (folder === "/") {
            return i18n.tr("File System")
        } else {
            return folder.substr(folder.lastIndexOf('/') + 1)
        }
    }

    property alias filemanager: root

    property bool wideAspect: width >= units.gu(80)

    FolderListPage {
        id: folderPage
        objectName: "folderPage"

        folder: root.homeFolder
    }
}

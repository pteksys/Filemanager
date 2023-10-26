/*
 * Copyright (C) 2013 Canonical Ltd
 * Copyright (C) 2021 UBports Foundation
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
import QtQuick 2.4
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Extras.PamAuthentication 0.1
import Qt.labs.settings 1.0
import Lomiri.Content 1.3
import Lomiri.Components.Themes 1.3

// This makes the Lomiri Thumbnailer available in all the other QML documents.
import Lomiri.Thumbnailer 0.1

import "ui"
import "backend" as Backend
import "authentication"

MainView {
    id: mainView
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "filemanager"
    applicationName: "filemanager.ubports"

    width: phone ? units.gu(40) : units.gu(100)
    height: units.gu(75)

    property color itemSubColor: "#0068bb"

    theme.name: "Lomiri.Components.Themes.Ambiance"
    theme.palette: Palette {
        selected.focus: "transparent"
        selected.overlay: "transparent"
        selected.base: "transparent"
        selected.activity: "transparent"
        selected.foreground: "transparent"
        selected.background: "transparent"

        normal.backgroundText: "white"
        normal.background: itemSubColor
        normal.overlay: itemSubColor
        normal.base: "white"
        normal.foreground: "transparent"
        normal.focus: "transparent"

        highlighted.focus: "transparent"
        highlighted.overlay: "transparent"
        highlighted.base: "transparent"
        highlighted.activity: "transparent"
        highlighted.foreground: "transparent"
        highlighted.background: "transparent"

        focused.focus: "transparent"
        focused.overlay: "transparent"
        focused.base: "transparent"
        focused.activity: "transparent"
        focused.foreground: "transparent"
        focused.background: "transparent"
    }

    property bool wideAspect: width > units.gu(80)

    property bool fullAccessGranted: noAuthentication || !authentication.requireAuthentication
    property bool isContentHub: false
    property bool importMode: true

    // This is used when it invokes folderListModel.setPathWithAuthentication()
    // We store user's preference only for the current instance of FM
    property bool sambaSavePassword: true

    QtObject {
        id: fileSelector
        property var activeTransfer: null
        property var fileSelectorComponent: null
    }

    Component {
        id: fileSelectorResultComponent
        ContentItem {}
    }

    AuthenticationHandler {
        id: authentication
        serviceName: mainView.applicationName
    }

    property var pageStack: pageStack

    function openFileSelector(selectFolderMode) {

        var currentItem = pageStack.currentPage
        if (currentItem && currentItem.objectName === "folderListPage") {

            currentItem.fileSelectorMode = !selectFolderMode
            currentItem.folderSelectorMode = selectFolderMode

            fileSelector.fileSelectorComponent = currentItem
        } else {
            var props = {
                fileSelectorMode: !selectFolderMode,
                folderSelectorMode: selectFolderMode
            }
            fileSelector.fileSelectorComponent = pageStack.push(Qt.resolvedUrl("./ui/FolderListPage.qml"), props)
        }
    }

    function cancelFileSelector() {
        console.log("Cancel file selector")
        pageStack.pop()
        fileSelector.fileSelectorComponent = null
        fileSelector.activeTransfer.state = ContentTransfer.Aborted
    }

    function acceptFileSelector(fileUrls) {
        console.log("accept file selector " + fileUrls)
        if (importMode) {
            importFiles(fileSelector.activeTransfer, fileUrls[0])
        } else {
            exportFiles(fileSelector.activeTransfer, fileUrls)
        }
    }

    function openLocalFile(filePath, share) {
        pageStack.push(Qt.resolvedUrl("content-hub/FileOpener.qml"), { fileUrl: "file://" + filePath, share: share} )
    }

    function startTransfer(activeTransfer, iMode) {
        if (activeTransfer.state === ContentTransfer.Charged || !iMode) {
            fileSelector.activeTransfer = activeTransfer
            isContentHub = true
            importMode = iMode
            openFileSelector(iMode)
        }
    }

    function importFiles(activeTransfer, destDir) {
        var succeededFileNames = []
        var failedFileNames = []
        var existingFileNames = []
        for(var i=0; i < activeTransfer.items.length; i++) {
            var item = activeTransfer.items[i]
            var destFilename = FmUtils.basename(String(item.url))
            console.log("Move file to:" + destDir + " with name: " + destFilename)

            if(FmUtils.exists(destDir + "/" + destFilename)) {
                console.log("detected existing file: " + destFilename)
                existingFileNames.push(destFilename)
            }

            if(activeTransfer.items[i].move(destDir, destFilename))
                succeededFileNames.push(destFilename)
            else
                failedFileNames.push(destFilename)
        }
        finishImport(destDir, succeededFileNames, failedFileNames, existingFileNames)
    }

    function exportFiles(activeTransfer, filesUrls) {
        var results = filesUrls.map(function(fileUrl) {
            return fileSelectorResultComponent.createObject(mainView, {"url": fileUrl})
        })

        if (activeTransfer !== null) {
            activeTransfer.items = results
            activeTransfer.state = ContentTransfer.Charged
            console.log("set activeTransfer")
        } else {
            console.log("activeTransfer null, not setting, testing code")
        }
    }


    Connections {
        target: ContentHub
        onExportRequested: startTransfer(transfer, false)
        onImportRequested: startTransfer(transfer, true)
        onShareRequested: startTransfer(transfer, true)
    }

    Rectangle {
        anchors.fill: parent
        color: itemSubColor
    }

    PageStack {
        id: pageStack
    }

    /* Settings Storage */
    property QtObject globalSettings: Backend.GlobalSettings { }


    function error(title, message) {
        var props = {
            title: title,
            text: message
        }

        PopupUtils.open(Qt.resolvedUrl("dialogs/NotifyDialog.qml"), mainView, props)
    }

    function finishImport(folder, okUrls, errUrls, existingUrls) {
        var okCount = okUrls.length
        var errCount = errUrls.length
        var existingCount = existingUrls.length

        var msg = ""
        if(okCount > 0)
            msg += i18n.tr("successfully saved: ") + i18n.tr("%1 file", "%1 files", okCount).arg(okCount)
        msg += msg.length > 0 ? "<br><br>\n" : ""
        if(errCount > 0)
            msg += i18n.tr("failed to save: ") + i18n.tr("%1 file", "%1 files", errCount).arg(errCount)
        msg += msg.length > 0 ? "<br>\n" : ""
        msg += i18n.tr("into: %1").arg(folder)

        if(existingCount > 0) {
            msg += msg.length > 0 ? "<br><br>\n" : ""
            msg += i18n.tr("Warning: Content-Hub does not overwrite existing files. The following were detected:")
            for(var i=0;i<existingCount;i++)
                msg += "<br>\n" + existingUrls[i]
        }

        fileSelector.fileSelectorComponent = null
        pageStack.currentPage.folderModel.path = folder
        pageStack.currentPage.folderModel.refresh()

        var props = {
            title: i18n.tr("Import Results"),
            text: msg
        }

        var popup = PopupUtils.open(Qt.resolvedUrl("dialogs/NotifyDialog.qml"), mainView, props)
        popup.closed.connect(function() {
            fileSelector.activeTransfer.state = ContentTransfer.Aborted
        })
    }

    Component.onCompleted:  {
        pageStack.push(Qt.resolvedUrl("ui/FolderListPage.qml"))
    }

    Rectangle {
        height: 4
        width: 100
        color: "#5C98C8"
        radius: height / 2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
    }
}

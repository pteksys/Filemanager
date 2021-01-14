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
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Qt.labs.settings 1.0
import Ubuntu.Content 1.3
import com.ubuntu.PamAuthentication 0.1

// This makes the Ubuntu Thumbnailer available in all the other QML documents.
import Ubuntu.Thumbnailer 0.1

import "ui"
import "backend" as Backend
import "authentication"

MainView {
    id: mainView
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "filemanager"
    applicationName: "com.ubuntu.filemanager"

    width: phone ? units.gu(40) : units.gu(100)
    height: units.gu(75)

    theme.name: {
        if (globalSettings.theme == 1) {
            return "Ubuntu.Components.Themes.Ambiance";
        } else if (globalSettings.theme == 2) {
            return "Ubuntu.Components.Themes.SuruDark";
        } else {
            return "";
        }
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
        var props = {
            fileSelectorMode: !selectFolderMode,
            folderSelectorMode: selectFolderMode
        }
        fileSelector.fileSelectorComponent = pageStack.push(Qt.resolvedUrl("./ui/FolderListPage.qml"), props)
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

        pageStack.pop()
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
}

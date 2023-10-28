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
 *              Niklas Wenzel <nikwen.developer@gmail.com>
 */
import QtQuick 2.4
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.FileManager.folderlistmodel 1.0

import "../components"
import "../actions" as FMActions
import "../dialogs" as Dialogs
import "../backend" as Backend
import "../views" as Views
import "../tooltips" as Tooltips

// TODO: Review last position code, which is referenced in FolderListModel (backend), FolderDelegateActions, FolderIconView, FolderListView, FolderListPageDefaultHeader, (PlacesPage)

SidebarPageLayout {
    id: folderListPage
    objectName: "folderListPage"

    property alias folderModel: pageModel
    property bool fileSelectorMode: false
    property bool folderSelectorMode: false
    property string tooltipMsg: ""

    Backend.FolderListModel {
        id: pageModel
        primSelItem: ""
        path: places.locationHome

        model.onlyAllowedPaths: !mainView.fullAccessGranted
        model.onNeedsAuthentication: {
            console.log("FolderListModel needsAuthentication() signal arrived")

            var props = {
                currentPath: urlPath,
                currentUserName: user,
                savePassword: mainView.sambaSavePassword
            }

            var popup = PopupUtils.open(Qt.resolvedUrl("../dialogs/NetAuthenticationDialog.qml"), mainView, props)

            popup.savePasswordChanged.connect(function() {
                mainView.sambaSavePassword = popup.savePassword
            })

            popup.ok.connect(function() {
                pageModel.setPathWithAuthentication(popup.currentPath,
                                                    popup.currentUserName,
                                                    popup.currentPassword,
                                                    popup.savePassword)
            })
        }

        model.onDownloadTemporaryComplete: {
            var paths = filename.split("/")
            var nameOnly = paths[paths.length -1]
            console.log("onDownloadTemporaryComplete received filename="+filename + "name="+nameOnly)
            openFromDisk(filename, nameOnly)
        }

        // Following properties are set from global settings, available in filemanager.qml
        model.showHiddenFiles: globalSettings.showHidden
        model.sortOrder: {
            var folderName = pageModel.path
            var isDateOrderingFolder = folderName.includes("Videos") || folderName.includes("Pictures")
            if (isDateOrderingFolder)
                return FolderListModel.SortDescending

            switch (globalSettings.sortOrder) {
            case 0: return FolderListModel.SortAscending
            case 1: return FolderListModel.SortDescending
            }
        }

        model.sortBy: {
            var folderName = pageModel.path
            var isDateOrderingFolder = folderName.includes("Videos") || folderName.includes("Pictures")
            if (isDateOrderingFolder)
                return FolderListModel.SortByDate

            switch (globalSettings.sortBy) {
            case 0: return FolderListModel.SortByName
            case 1: return FolderListModel.SortByDate
            case 2: return FolderListModel.SortBySize
            }
        }

        onPathChanged: pageModel.model.selectionObject.clear()
    }

    sidebarWidth: globalSettings.sidebarWidth
    onSidebarWidthChanged: {
        if (sidebarWidth > sidebarMaximumWidth)
            globalSettings.sidebarWidth = sidebarMaximumWidth
        else if (sidebarWidth < sidebarMinimumWidth)
            globalSettings.sidebarWidth = sidebarMinimumWidth
        else
            globalSettings.sidebarWidth = folderListPage.sidebarWidth
    }

    Binding {
        when: !sidebarResizing
        target: folderListPage
        property: "sidebarWidth"
        value: globalSettings.sidebarWidth
    }

    sidebarActive: mainView.wideAspect
    sidebarLoader.sourceComponent: PlacesPage {
        anchors.fill: parent
        folderModel: pageModel
    }

    mainLoader.sourceComponent: Page {
        id: folderPage

        // *** HEADERS ***

        header: defaultHeader

        FolderListPageDefaultHeader {
            id: defaultHeader
            fileOperationDialog: fileOperationDialogObj
            folderPage: folderListPage
            folderModel: pageModel
            showPanelAction: folderListPage.showPanelAction
            visible: !selectionMode
            enabled: visible
        }

        FolderListPageSelectionHeader {
            id: selectionHeader
            fileOperationDialog: fileOperationDialogObj
            folderPage: folderListPage
            folderModel: pageModel
            selectorMode: fileSelectorMode
            openDefault: globalSettings.openDefault
            visible: selectionMode && !isContentHub
            enabled: visible
        }

        FolderListPagePickModeHeader {
            id: pickModeHeader
            folderModel: pageModel
            visible: selectionMode && isContentHub
            enabled: visible
        }

        // FIXME: Clearing selection (by cancel btn in the header, or changing the folder, should exit selection mode)
        readonly property bool selectionMode: fileSelectorMode || folderSelectorMode

        Loader {
            id: viewLoader
            anchors.fill: parent
            anchors.topMargin: folderPage.header.height
            anchors.bottomMargin: bottomTooltip.height


            sourceComponent: {
                if (globalSettings.viewMethod === 1) { // Grid
                    return folderIconView
                } else {
                    return folderListView
                }
            }
        }

        BottomPanelStack {
            id: bottomPanelStack

            onHeightChanged: console.log(height)

            Tooltips.BottomTooltip {
                id: bottomTooltip
                message: tooltipMsg
                visible: false
                onMessageChanged: {
                    visible = true && tooltipMsg != ""
                    tooltipTimer.restart()
                }
            }
        }


        Rectangle {
            anchors { bottom: bottomPanelStack.top; left: parent.left; right: parent.right; }
            height: units.dp(1)
            color: theme.palette.normal.base
            visible: viewLoader.item.flickableItem.contentHeight > viewLoader.item.flickableItem.height
        }

        // *** VIEW COMPONENTS ***

        Component {
            id: folderIconView
            Views.FolderIconView {
                anchors.fill: parent
                folderModel: pageModel
                folderListPage: folderPage
                fileOperationDialog: fileOperationDialogObj
                openDefault: globalSettings.openDefault
                header: pageModel.count > 0 && !folderModel.model.isCurAllowedPath && folderModel.model.onlyAllowedPaths
                        ? authReqHeader
                        : null
            }
        }

        Component {
            id: folderListView
            Views.FolderListView {
                anchors.fill: parent
                folderModel: pageModel
                folderListPage: folderPage
                fileOperationDialog: fileOperationDialogObj
                openDefault: globalSettings.openDefault
                header: pageModel.count > 0 && !folderModel.model.isCurAllowedPath && folderModel.model.onlyAllowedPaths
                        ? authReqHeader
                        : null
            }
        }

        FMActions.UnlockFullAccess {
            id: authAction
            onTriggered: {
                console.log("Full access clicked")
                authentication.authenticate()

                authentication.authenticationSucceeded.connect(function() {
                    console.log("Authentication for full access succeeded!")
                    mainView.fullAccessGranted = true
                })
            }
        }

        Component {
            id: authReqHeader
            ListItem {
                anchors { left: parent.left; right: parent.right }
                divider.visible: false
                height: layout.height
                ListItemLayout {
                    id: layout
                    title.text: i18n.tr("Restricted access")
                    title.maximumLineCount: 2
                    title.wrapMode: Text.WordWrap

                    subtitle.text: i18n.tr("Authentication is required in order to see all the content of this folder.")
                    subtitle.maximumLineCount: Math.MAX_VALUE
                    subtitle.wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    Button {
                        SlotsLayout.position: SlotsLayout.Last
                        color: theme.palette.normal.positive
                        action: authAction
                    }
                }
            }
        }

        Loader {
            id: emptyStateLoader
            anchors.fill: parent
            active: !folderModel.busy
            sourceComponent: {
                if (folderModel.count == 0 && !folderModel.model.isCurAllowedPath && folderModel.model.onlyAllowedPaths)
                    return authEmptyState

                if (folderModel.count == 0)
                    return noFilesEmptyState
            }

            ActivityIndicator {
                anchors.centerIn: parent
                running: folderModel.busy
            }
        }

        Component {
            id: noFilesEmptyState

            Item {
                anchors.fill: parent
                EmptyState {
                    anchors.centerIn: parent
                    iconName: "document-open"
                    title: i18n.tr("No files")
                    subTitle: i18n.tr("This folder is empty.")
                }
            }
        }

        Component {
            id: authEmptyState

            Item {
                anchors.fill: parent
                EmptyState {
                    anchors.centerIn: parent
                    iconName: "lock"
                    title: i18n.tr("Restricted access")
                    subTitle: i18n.tr("Authentication is required in order to see the content of this folder.")

                    controlComponent: Button {
                        width: units.gu(24)
                        action: authAction
                    }
                }
            }
        }

        // Errors from model
        Connections {
            target: pageModel.model
            onError: {
                console.log("FolderListModel Error Title/Description", errorTitle, errorMessage)
                error(i18n.tr("File operation error"), errorTitle + ": " + errorMessage)
            }
        }

        Dialogs.FileOperationProgressDialog {
            id: fileOperationDialogObj

            page: folderPage
            model: pageModel.model
        }

        function openFromDisk(fullpathname, name, share) {
            console.log("openFromDisk():"+ fullpathname)
            // Check if file is an archive. If yes, ask the user whether he wants to extract it
            var archiveType = pageModel.getArchiveType(name)
            if (archiveType === "") {
                openLocalFile(fullpathname, share)
            } else {
                var props = {
                    "filePath" : fullpathname,
                    "fileName" : name,
                    "archiveType" : archiveType,
                    "folderListPage" : folderPage,
                    "folderModel": pageModel
                }
                PopupUtils.open(Qt.resolvedUrl("../dialogs/OpenArchiveDialog.qml"), mainView, props)
            }

        }

        //High Level openFile() function
        //remote files are saved as temporary files and then opened
        // TODO: This is deprecated. Should be removed, with all the actions that actually uses it.
        function openFile(model, share) {
            if (model.isRemote) {
                //download and open later when the signal downloadTemporaryComplete() arrives
                pageModel.model.downloadAsTemporaryFile(model.index)
            }
            else {
                openFromDisk(model.filePath, model.fileName, share)
            }
        }

        Component.onCompleted: {
            forceActiveFocus()
        }

        Timer {
            id: tooltipTimer
            repeat: true
            interval: 2000
            onTriggered: {
                bottomTooltip.visible = false
            }
        }
    }
}

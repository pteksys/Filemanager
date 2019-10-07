import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

import "../components" as Components
import "../actions" as FMActions
import "../views" as Views


PageHeader {
    id: rootItem

    property bool __actionsEnabled: (selectionManager.counter > 0) || (folderSelectorMode && folderModel.model.isWritable)
    property bool __actionsVisible: selectionMode

    property var folderPage
    property var folderModel
    property var selectedItem
    property var selectionManager: folderModel.model.selectionObject
    property var selectorMode
    property var fileOperationDialog
    property var openDefault

    property var __delegateActions: Views.FolderDelegateActions {
        folderListPage: folderModel
        folderModel: folderPage.folderModel
        fileOperationDialog: fileOperationDialog
        openDefault: openDefault
    }

    title: FmUtils.basename(folderModel.path)

    contents: ListItemLayout {
        anchors.verticalCenter: parent.verticalCenter
        subtitle.text: rootItem.title
        title.text: i18n.tr("%1 item selected", "%1 items selected",selectionManager.counter).arg(folderModel.model.selectionObject.counter)
    }

    extension: Components.PathHistoryRow {
        folderModel: rootItem.folderModel
    }

    leadingActionBar.actions: Action {
        text: i18n.tr("Cancel")
        iconName: "close"
        onTriggered: {
            console.log("FileSelector cancelled")
            selectionManager.clear()
            fileSelectorMode = false
            fileSelector.fileSelectorComponent = null
        }
    }

    trailingActionBar.numberOfSlots: 5
    trailingActionBar.anchors.rightMargin: 0
    trailingActionBar.actions: [
        FMActions.SelectUnselectAll {
            selectedAll: selectionManager.selectedAll
            onTriggered: {
                if (selectionManager.selectedAll) {
                    selectionManager.clear()
                } else {
                    selectionManager.selectAll()
                }
            }
        },

        FMActions.FileCopy {
            property bool smallText: true
            enabled: __actionsEnabled
            visible: __actionsVisible
            onTriggered: {
                var selectedAbsPaths = selectionManager.selectedAbsFilePaths();
                folderModel.model.copyPaths(selectedAbsPaths)
                selectionManager.clear()
                fileSelectorMode = false
                fileSelector.fileSelectorComponent = null
            }
        },

        FMActions.FileCut {
            property bool smallText: true
            enabled: __actionsEnabled
            visible: __actionsVisible && folderModel.model.isWritable
            onTriggered: {
                var selectedAbsPaths = selectionManager.selectedAbsFilePaths();
                folderModel.model.cutPaths(selectedAbsPaths)
                selectionManager.clear()
                fileSelectorMode = false
                fileSelector.fileSelectorComponent = null
            }
        },

        FMActions.OpenAdvanced {
            property bool smallText: true
            enabled: __actionsEnabled
            visible: __actionsVisible && !folderModel.primSelItem.isBrowsable && openDefault && selectionManager.counter == 1
            onTriggered: __delegateActions.openAdvanced(folderModel.primSelItem)
        },

        FMActions.Rename {
            visible: __actionsVisible && folderModel.model.isWritable && selectionManager.counter == 1
            onTriggered: {
                var props = {
                    "modelRow" : folderModel.primSelItem.index,
                    "inputText" : folderModel.primSelItem.fileName,
                    "placeholderText" : folderModel.primSelItem.fileName,
                    "folderModel": folderModel.model
                }

                var popup = PopupUtils.open(Qt.resolvedUrl("../dialogs/ConfirmRenameDialog.qml"), mainView, props)

                popup.accepted.connect(function(inputText) {
                    console.log("Rename accepted", inputText)
                    if (inputText !== '') {
                        console.log("Rename commensed, modelRow/inputText", fileOperationDialog.index, inputText.trim())
                        if (folderModel.model.rename(folderModel.primSelItem.index, inputText.trim()) === false) {
                            var props = {
                                title: i18n.tr("Could not rename"),
                                text: i18n.tr("Insufficient permissions, name contains special chars (e.g. '/'), or already exists")
                            }
                            PopupUtils.open(Qt.resolvedUrl("../dialogs/NotifyDialog.qml"), mainView, props)
                        }
                        selectionManager.clear()
                        fileSelectorMode = false
                    } else {
                        console.log("Empty new name given, ignored")
                    }
                })
            }
        },

        FMActions.Delete {
            property bool smallText: true
            enabled: __actionsEnabled
            visible: __actionsVisible && folderModel.model.isWritable
            onTriggered: {
                var selectedAbsPaths = selectionManager.selectedAbsFilePaths();

                var props = {
                    "paths" : selectedAbsPaths,
                    "folderModel": folderModel.model,
                    "fileOperationDialog": fileOperationDialog
                }

                PopupUtils.open(Qt.resolvedUrl("../dialogs/ConfirmMultipleDeleteDialog.qml"), mainView, props)
            }
        },

        FMActions.Properties {
            visible: selectionManager.counter == 1
            onTriggered: {
                var props = {
                    "model": folderModel.primSelItem
                }
                PopupUtils.open(Qt.resolvedUrl("../ui/FileDetailsPopover.qml"), mainView, props)
            }
        }
    ]


    // *** STYLE HINTS ***

    StyleHints { dividerColor: "transparent" }
}

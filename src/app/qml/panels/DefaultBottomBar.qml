import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

import "../actions" as FMActions
import "../components" as Components
import "template" as Template

Template.Panel {
    id: bottomBar

    property var folderModel
    property var fileOperationDialog

    ActionList {
        id: leadingActions

        FMActions.FilePaste {
            property bool smallText: true
            clipboardUrlsCounter: folderModel.model.clipboardUrlsCounter
            visible: folderModel.model.clipboardUrlsCounter > 0
            onTriggered: {
                console.log("Pasting to current folder items of count " + folderModel.model.clipboardUrlsCounter)
                fileOperationDialog.startOperation(i18n.tr("Paste files"))
                folderModel.model.paste()

                // We want this in a mobile environment.
                folderModel.model.clearClipboard()
            }
        }
    }

    ActionList {
        id: trailingActions

        FMActions.FileClearSelection {
            clipboardUrlsCounter: folderModel.model.clipboardUrlsCounter
            visible: folderModel.model.clipboardUrlsCounter > 0
            onTriggered: {
                console.log("Clearing clipboard")
                folderModel.model.clearClipboard()
            }
        }
    }

    ActionBar {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        delegate: Components.TextualButtonStyle { }
        actions: leadingActions.children  // WORKAROUND: 'actions' is a non-NOTIFYable property
    }

    ActionBar {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        delegate: Components.TextualButtonStyle { }
        actions: trailingActions.children  // WORKAROUND: 'actions' is a non-NOTIFYable property
    }
}

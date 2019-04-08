import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

import "../components" as Components
import "../actions" as FMActions

PageHeader {
    id: rootItem

    // temp
    property var fileOperationDialog
    property var folderModel
    property var showPanelAction

    title: FmUtils.basename(folderModel.path)

    contents: ListItemLayout {
        anchors.verticalCenter: parent.verticalCenter
        title.text: rootItem.title
        subtitle.text: i18n.tr("%1 item", "%1 items", folderModel.count).arg(folderModel.count)
    }

    extension: Components.PathHistoryRow {
        folderModel: rootItem.folderModel
    }

    FMActions.GoBack {
        id: goBackAction
        onTriggered: folderModel.goBack()
    }

    FMActions.PlacesBookmarks {
        id: placesBookmarkAction
        onTriggered: {
            var pp = pageStack.push(Qt.resolvedUrl("PlacesPage.qml"), { folderModel: rootItem.folderModel })
            pp.pathClicked.connect(function() {
                pp.pageStack.pop()
            })
        }
    }

    leadingActionBar.actions: showPanelAction.visible ? showPanelAction : placesBookmarkAction

    trailingActionBar.numberOfSlots: 4
    trailingActionBar.actions: [
        FMActions.Settings {
            onTriggered: PopupUtils.open(Qt.resolvedUrl("ViewPopover.qml"), mainView, { folderListModel: folderModel.model })
        },
        FMActions.Properties {
            onTriggered: {
                print(text)
                PopupUtils.open(Qt.resolvedUrl("../ui/FileDetailsPopover.qml"), mainView,{ "model": folderModel.model })
            }
        },
        FMActions.AddBookmark {
            onTriggered: {
                print(text)
                folderModel.places.addLocation(folderModel.model.path)

            }
        },
        FMActions.NewItem {
            property bool smallText: true
            enabled: folderModel.model.isWritable
            onTriggered: {
                print(text)
                PopupUtils.open(Qt.resolvedUrl("../dialogs/CreateItemDialog.qml"), mainView, { folderModel: folderModel.model })
            }
        }
    ]

    // *** STYLE HINTS ***

    StyleHints { dividerColor: "transparent" }
}


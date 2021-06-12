import QtQuick 2.4
import QtQuick.Layouts 1.12
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

import "../components" as Components
import "../actions" as FMActions

PageHeader {
    id: rootItem

    // temp
    property var fileOperationDialog
    property var folderPage
    property var folderModel
    property var showPanelAction
    property var popover
    property bool showSearchBar: false
    property bool searchRecursiveOptionChecked: false
    property bool searchFilesOptionChecked: false
    property int queryModeIndex: 0

    title: FmUtils.basename(folderModel.path)

    contents: Item {
        anchors.fill: parent

        ListItemLayout {
            anchors.verticalCenter: parent.verticalCenter
            title.text: rootItem.title
            subtitle.text: i18n.tr("%1 item", "%1 items", folderModel.count).arg(folderModel.count)
        }

        TextField {
            id: searchField
            visible: showSearchBar
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }

            function __openPopover() {
                if (!popover) {
                    popover = PopupUtils.open(popoverComponent, this)
                    this.forceActiveFocus()
                }
            }

            function __closePopover() {
                if (popover) {
                    PopupUtils.close(popover)
                    popover = null
                }
            }

            placeholderText: i18n.tr("Search...")

            // Disable predictive text
            inputMethodHints: Qt.ImhNoPredictiveText

            // Force active focus when this becomes the current PageHead state and
            // show OSK if appropriate.
            onVisibleChanged: if (visible) forceActiveFocus()
            onActiveFocusChanged: {
                if (!popover && activeFocus)
                    this.__openPopover()
                else if (popover && !activeFocus)
                    this.__closePopover()
            }

            // https://stackoverflow.com/questions/41232999/two-way-binding-c-model-in-qml
            text: folderModel.model.searchString

            Binding {
                target: folderModel.model
                property: "searchString"
                value: searchField.text
            }
        }

        Component {
            id: popoverComponent

            Popover {
                id: popover
                contentWidth: searchField.width
                autoClose: false

                Column {
                    id: containerLayout
                    anchors {
                        left: parent.left
                        top: parent.top
                        right: parent.right
                    }

                    ListItem {
                        height: filesOptionLayout.height + (divider.visible ? divider.height : 0)
                        ListItemLayout {
                            id: filesOptionLayout
                            title.text: i18n.tr("Search in Files")

                            CheckBox {
                                checked: searchFilesOptionChecked
                                onCheckedChanged: {
                                    searchFilesOptionChecked = checked
                                    folderModel.model.setSearchInFiles(checked)
                                }
                            }
                        }
                    }

                    ListItem {
                        height: recursiveOptionLayout.height + (divider.visible ? divider.height : 0)
                        ListItemLayout {
                            id: recursiveOptionLayout
                            title.text: i18n.tr("Search Recursively")
                            summary.text: i18n.tr("Note: Slow in large directories")
                            summary.wrapMode: Text.WrapAtWordBoundaryOrAnywhere

                            CheckBox {
                                checked: searchRecursiveOptionChecked
                                onCheckedChanged: {
                                    searchRecursiveOptionChecked = checked
                                    folderModel.model.setSearchRecursive(checked)
                                }
                            }
                        }
                    }
                }
            }
        }
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

    trailingActionBar.numberOfSlots: 5
    trailingActionBar.actions: [
        FMActions.Settings {
            visible: !folderModel.model.clipboardUrlsCounter > 0 && !showSearchBar
            onTriggered: PopupUtils.open(Qt.resolvedUrl("ViewPopover.qml"), mainView, { folderListModel: folderModel.model })
        },
        FMActions.Properties {
            onTriggered: {
                print(text)
                PopupUtils.open(Qt.resolvedUrl("../ui/FileDetailsPopover.qml"), mainView,{ "model": folderModel.model })
            }
        },
        FMActions.Terminal {
            onTriggered: {
                print(text)
                Qt.openUrlExternally("terminal://?path=" + folderModel.model.path)
            }
        },
        FMActions.NewItem {
            visible: !showSearchBar
            property bool smallText: true
            enabled: folderModel.model.isWritable
            onTriggered: {
                print(text)
                PopupUtils.open(Qt.resolvedUrl("../dialogs/CreateItemDialog.qml"), mainView, { folderPage: folderPage, folderModel: folderModel.model })
            }
        },
        FMActions.AddBookmark {
            visible: !folderModel.model.clipboardUrlsCounter > 0 && !showSearchBar
            onTriggered: {
                print(text)
                folderModel.places.addLocation(folderModel.model.path)
                folderPage.tooltipMsg = i18n.tr("Added '%1' to Places").arg(folderModel.model.fileName)

            }
        },
        FMActions.FileClearSelection {
            clipboardUrlsCounter: folderModel.model.clipboardUrlsCounter
            visible: folderModel.model.clipboardUrlsCounter > 0
            onTriggered: {
                console.log("Clearing clipboard")
                folderModel.model.clearClipboard()
                folderPage.tooltipMsg = i18n.tr("Cleared clipboard")
            }
        },
        FMActions.FilePaste {
            property bool smallText: true
            clipboardUrlsCounter: folderModel.model.clipboardUrlsCounter
            visible: folderModel.model.clipboardUrlsCounter > 0
            onTriggered: {
                console.log("Pasting to current folder items of count " + folderModel.model.clipboardUrlsCounter)
                fileOperationDialog.startOperation(i18n.tr("Paste files"))
                folderModel.model.paste()
                folderPage.tooltipMsg = i18n.tr("Pasted item", "Pasted items", folderModel.model.clipboardUrlsCounter)

                // We want this in a mobile environment.
                folderModel.model.clearClipboard()
            }
        },
        FMActions.Search {
            id: searchButton
            onTriggered: {
                showSearchBar = !showSearchBar;
                if (popover && !showSearchBar) {
                    searchField.__closePopover()
                }
            }
        }
    ]

    // *** STYLE HINTS ***

    StyleHints { dividerColor: "transparent" }
}

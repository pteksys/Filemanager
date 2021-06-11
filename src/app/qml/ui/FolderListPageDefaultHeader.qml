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
    property var popup
    property bool showSearchBar: false
    property bool recursiveOptionChecked: false
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

            placeholderText: i18n.tr("Filter...")

            // Disable predictive text
            inputMethodHints: Qt.ImhNoPredictiveText

            // Force active focus when this becomes the current PageHead state and
            // show OSK if appropriate.
            onVisibleChanged: if (visible) { popup = PopupUtils.open(popoverComponent, this); forceActiveFocus() }
            onActiveFocusChanged: {
                if (!popup && activeFocus && searchMouseField.containsMouse) {
                    popup = PopupUtils.open(popoverComponent, this)
                }
                else if (popup && !activeFocus) {
                    PopupUtils.close(popup)
                    popup = null
                }
            }

            MouseArea {
                id: searchMouseField
                anchors.fill: parent
                hoverEnabled: true
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
                contentWidth: searchField.width
                autoClose: false
                id: popover

                Column {
                    id: containerLayout
                    anchors {
                        left: parent.left
                        top: parent.top
                        right: parent.right
                    }

                    Row {
                        id: choicesRow
                        SlotsLayout.position: SlotsLayout.Last
                        height: units.gu(4)
                        anchors.horizontalCenter: parent.horizontalCenter

                        Repeater {
                            model: [ i18n.tr("Filter"), i18n.tr("Search") ]

                            delegate: AbstractButton {
                                id: del
                                property bool isSelected: model.index == rootItem.queryModeIndex

                                onClicked: {
                                    if (model.index == 0) {
                                        searchField.placeholderText = i18n.tr("Filter...")
                                        folderModel.model.setQueryModeFilter(true)
                                    }
                                    else {
                                        searchField.placeholderText = i18n.tr("Search...")
                                        folderModel.model.setQueryModeFilter(false)
                                    }
                                    rootItem.queryModeIndex = model.index
                                }

                                width: delLabel.width + units.gu(2)
                                height: parent.height

                                Rectangle {
                                    anchors.fill: parent
                                    color: theme.palette.selected.base
                                    visible: del.pressed
                                }

                                Label {
                                    id: delLabel
                                    anchors.centerIn: parent
                                    text: modelData
                                    textSize: Label.Medium
                                    color: isSelected ? theme.palette.normal.backgroundText : theme.palette.disabled.backgroundText
                                }
                            }
                        }
                    }

                    ListItem {
                        height: recursiveOptionLayout.height + (divider.visible ? divider.height : 0)
                        ListItemLayout {
                            id: recursiveOptionLayout
                            title.text: i18n.tr("Recursive")
                            subtitle.text: i18n.tr("Note: Slow in large directories")

                            CheckBox {
                                checked: recursiveOptionChecked
                                onCheckedChanged: {
                                    recursiveOptionChecked = checked
                                    folderModel.model.setQueryModeRecursive(checked)
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
            visible: !folderModel.model.clipboardUrlsCounter > 0
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
            property bool smallText: true
            enabled: folderModel.model.isWritable
            onTriggered: {
                print(text)
                PopupUtils.open(Qt.resolvedUrl("../dialogs/CreateItemDialog.qml"), mainView, { folderPage: folderPage, folderModel: folderModel.model })
            }
        },
        FMActions.AddBookmark {
            visible: !folderModel.model.clipboardUrlsCounter > 0
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
                if (popup && !showSearchBar) {
                    PopupUtils.close(popup)
                    popup = null
                }
            }
        }
    ]

    // *** STYLE HINTS ***

    StyleHints { dividerColor: "transparent" }
}

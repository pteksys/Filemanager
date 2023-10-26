import QtQuick 2.4
import QtQuick.Layouts 1.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Styles 1.3
import Lomiri.Components.Themes.Ambiance 1.3

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
            id: titleItem
            anchors.verticalCenter: parent.verticalCenter
            title.text: showSearchBar && searchField.text.trim().length ? t_metrics.text : rootItem.title
            subtitle.text: ""
            title.elide: Text.ElideRight
            title.wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            title.maximumLineCount: 3
            width: showSearchBar ? Math.max(units.gu(15), t_metrics.width*0.75) : parent.width

            TextMetrics {
                id: t_metrics
                font: parent.title.font
                text: i18n.tr("Search Results")
            }
        }

        Component {
            id: popoverComponent

            Popover {
                id: popover
                contentWidth: Math.max(searchField.width, units.gu(22))
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
                            title.text: i18n.tr("File Contents")

                            CheckBox {
                                checked: searchFilesOptionChecked
                                onCheckedChanged: {
                                    searchFilesOptionChecked = checked
                                    folderModel.model.setSearchFileContents(checked)
                                }
                            }
                        }
                    }

                    ListItem {
                        height: recursiveOptionLayout.height + (divider.visible ? divider.height : 0)
                        ListItemLayout {
                            id: recursiveOptionLayout
                            title.text: i18n.tr("Recursive")
                            summary.text: i18n.tr("Note: Slow in large directories")
                            summary.wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            summary.color: "white"
                            subtitle.color: "white"

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

    extension: Item {
        anchors { left: parent.left; right: parent.right }
        implicitHeight: units.gu(6) + 10 * 2

        Rectangle {
            anchors.fill: searchField
            color: "transparent"
            border.width: 1
            radius: 10
            border.color: "white"
            visible: searchField.visible

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: i18n.tr("Search...")
                color: "white"
                visible: searchField.text == ""
            }
        }

        TextField {
            id: searchField
            visible: rootItem.title.endsWith("Documents") || rootItem.title.endsWith("Music")
            anchors.fill: parent
            anchors.margins: 10
            color: "white"

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

            // Disable predictive text
            inputMethodHints: Qt.ImhNoPredictiveText

            // Force active focus when this becomes the current PageHead state and
            // show OSK if appropriate.
            onVisibleChanged: {
                if (!visible)
                    folderModel.model.setSearchString("");
            }
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

            style: TextFieldStyle {
                background: Item {
                }
            }
        }
    }

    leadingActionBar.delegate: Item {
        width: height
        height: leadingActionBar.height

        Icon {
            name: modelData.iconName
            width: units.gu(3)
            height: width
            color: "white"
            anchors.centerIn: parent
        }

        MouseArea {
            anchors.fill: parent
            onClicked: modelData.trigger()
        }
    }
    leadingActionBar.actions: folderModel.canGoBack ? [ goBackAction ] : []

    trailingActionBar.numberOfSlots: 5
    trailingActionBar.delegate: Item {
        width: height
        height: trailingActionBar.height

        Icon {
            name: modelData.iconName
            width: units.gu(3)
            height: width
            color: "white"
            anchors.centerIn: parent
        }

        MouseArea {
            anchors.fill: parent
            onClicked: modelData.trigger()
        }
    }
    trailingActionBar.actions: [
        FMActions.Settings {
            onTriggered: PopupUtils.open(Qt.resolvedUrl("ViewPopover.qml"), mainView, { folderListModel: folderModel.model })
        },
        FMActions.Properties {
            visible: !showSearchBar
            onTriggered: {
                print(text)
                PopupUtils.open(Qt.resolvedUrl("../ui/FileDetailsPopover.qml"), mainView,{ "model": folderModel.model })
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
        FMActions.FileClearSelection {
            clipboardUrlsCounter: folderModel.model.clipboardUrlsCounter
            visible: folderModel.model.clipboardUrlsCounter > 0 && !showSearchBar
            onTriggered: {
                console.log("Clearing clipboard")
                folderModel.model.clearClipboard()
                folderPage.tooltipMsg = i18n.tr("Cleared clipboard")
            }
        },
        FMActions.FilePaste {
            property bool smallText: true
            clipboardUrlsCounter: folderModel.model.clipboardUrlsCounter
            visible: folderModel.model.clipboardUrlsCounter > 0 && !showSearchBar
            onTriggered: {
                console.log("Pasting to current folder items of count " + folderModel.model.clipboardUrlsCounter)
                fileOperationDialog.startOperation(i18n.tr("Paste files"))
                folderModel.model.paste()
                folderPage.tooltipMsg = i18n.tr("Pasted item", "Pasted items", folderModel.model.clipboardUrlsCounter)

                // We want this in a mobile environment.
                folderModel.model.clearClipboard()
            }
        },
        FMActions.Terminal {
            visible: !showSearchBar
            onTriggered: {
                print(text)
                Qt.openUrlExternally("terminal://?path=" + folderModel.model.path)
            }
        }
    ]

    // *** STYLE HINTS ***

    StyleHints {
        foregroundColor: "white"
        backgroundColor: "transparent"
        dividerColor: "transparent"
        pressedBackgroundColor: "transparent"
    }
}

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

import "../components" as Components
import "../actions" as FMActions
import "../backend"

PageHeader {
    id: rootItem

    // temp
    property FolderListModel folderModel
    property var selectionManager: folderModel.model.selectionObject
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
            subtitle.text: {
                if (!isContentHub)
                    i18n.tr("%1 item", "%1 items", folderModel.count).arg(folderModel.count)
                else if (importMode)
                    i18n.tr("Save here")
                else
                    i18n.tr("Select files (%1 selected)", selectionManager.counter).arg(folderModel.model.selectionObject.counter)
            }

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

        TextField {
            id: searchField
            visible: showSearchBar
            anchors {
                right: parent.right
                left: titleItem.right
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
            onVisibleChanged: {
                folderModel.model.setImporting(isContentHub && importMode);
                if (visible)
                    forceActiveFocus()
                else
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
                        visible: !importMode
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
        onTriggered: lastPos = folderModel.goBack()
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

    trailingActionBar {
        anchors.rightMargin: 0

        actions: [
            FMActions.Cancel {
                text: i18n.tr("Cancel")
                iconName: "close"
                onTriggered: {
                    console.log("FileSelector cancelled")
                    cancelFileSelector()
                }
            },

            FMActions.Select {
                enabled: selectionManager.counter > 0 || importMode
                onTriggered: {
                    var selectedAbsUrls = []
                    if (folderSelectorMode) {
                        selectedAbsUrls = [ folderModel.path ]
                    } else {
                        var selectedAbsPaths = selectionManager.selectedAbsFilePaths();
                        // For now support only selection in filesystem
                        selectedAbsUrls = selectedAbsPaths.map(function(item) {
                            return "file://" + item;
                        });
                    }
                    console.log("FileSelector OK clicked, selected items: " + selectedAbsUrls)
                    acceptFileSelector(selectedAbsUrls)
                }
            },

            FMActions.Search {
                id: searchButton
                onTriggered: {
                    showSearchBar = !showSearchBar;
                    if (popover && !showSearchBar)
                        searchField.__closePopover()
                }
            }
        ]
    }


    // *** STYLE HINTS ***

    StyleHints { dividerColor: "transparent" }
}

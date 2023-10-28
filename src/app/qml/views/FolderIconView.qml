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
 * Authored by: Michael Spencer <sonrisesoftware@gmail.com>
 */
import QtQuick 2.4
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3

import "../components"

ScrollView {
    id: folderIconView

    property var folderListPage
    property var fileOperationDialog
    property var folderModel
    property var selectedItem
    property var openDefault

    function calcCellwidth () {
        var s = 12 // default
        switch (globalSettings.gridSize) {
            case 0: s = 10
                break
            case 1: s = 12
                break
            case 2: s = 16
                break
            case 3: s = 22
                break
            }
        return units.gu(s)
    }

    GridSectionView {
        id: view
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20

        columns: width / (cellWidth + columnSpacing)

        cellWidth: calcCellwidth()
        cellHeight: cellWidth + units.gu(2)

        model: folderModel.model

        PullToRefresh {
            parent: view
            onRefresh: {
                refreshing = true
                folderModel.goTo(folderModel.model.filePath)
                refreshing = false
            }
        }

        itemDelegate: FolderIconDelegate {
            id: delegate
            width: view.cellWidth
            height: view.cellHeight

            iconName: model.iconName
            title: model.stylizedFileName
            isSelected: model.isSelected
            path: model.filePath

            property var __delegateActions: FolderDelegateActions {
                folderListPage: folderIconView.folderListPage
                folderModel: folderIconView.folderModel
                fileOperationDialog: folderIconView.fileOperationDialog
                openDefault: folderIconView.openDefault
            }

            onClicked: {
                if (mouse.button === Qt.RightButton) {
                    delegate.pressAndHold(mouse)
                } else {
                    __delegateActions.itemClicked(model)
                }
            }

            onPressAndHold: {
                folderModel.primSelItem = model
                __delegateActions.listLongPress(model)
            }
        }

        property string folderName: folderModel.path
        property bool isDateOrderingFolder: folderName.includes("Videos") || folderName.includes("Pictures")
        sectionProperty: isDateOrderingFolder ? "dateOrdering" : "isDir"
        sectionDelegate: SectionDivider {
            property var section
            text: {
                if (view.isDateOrderingFolder) {
                    return section
                } else {
                    return section == true ? i18n.tr("Directories") : i18n.tr("Files")
                }
            }
        }
    }
}

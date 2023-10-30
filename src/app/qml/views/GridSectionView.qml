import QtQuick 2.12
import QtQuick.Layouts 1.12

Flickable {
    id: root
    property alias columns: layout.columns
    property alias columnSpacing: layout.columnSpacing
    property QtObject model
    property Component header: Item {}
    property Component itemDelegate: Item {}
    property Component sectionDelegate: Item {}
    property string sectionProperty: ""
    property int cellWidth: 40
    property int cellHeight: 40
    contentHeight: column.childrenRect.height
    contentWidth: width

    function fillLayout() {
        console.log("fillLayout: " + root.model.count)
        layout.children = []
        var lastSection = "";
        for(var i = 0;i < root.model.count;i ++)
        {
            var element = root.model.get(i);
            var section = element[root.sectionProperty];
            if(section !== lastSection) {
                console.log("New section: " + section)
                root.sectionDelegate.createObject(layout, {
                                                      "section": section,
                                                      "Layout.columnSpan": root.columns,
                                                      "Layout.preferredHeight": units.gu(4)
                                                  });
            }

            root.itemDelegate.createObject(layout, {
                                               "model": element,
                                               "Layout.preferredHeight": cellHeight,
                                               "Layout.preferredWidth": cellWidth
                                           });
            lastSection = section;
        }
    }

    Component.onCompleted: {
        console.log("onCompleted: " + root.model.count)
        fillLayout()
    }

    Connections {
        target: model
        onCountChanged: {
            console.log("onCountChanged: " + root.model.count)
            fillLayout()
        }
        onPathChanged: {
            console.log("onPathChanged: " + root.model.count)
            fillLayout()
        }
    }

    Connections {
        target: globalSettings
        onGridSizeChanged: {
            console.log("onGridSizeChanged: " + root.model.count)
            fillLayout()
        }
    }

    Column {
        id: column

        Loader {
            anchors.left: parent.left
            anchors.right: parent.right
            active: true
            sourceComponent: header
        }

        GridLayout {
            id: layout
            columnSpacing: 4
            rowSpacing: columnSpacing
        }
    }
}

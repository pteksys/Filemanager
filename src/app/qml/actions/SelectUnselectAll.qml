import QtQuick 2.4
import Lomiri.Components 1.3

Action {
    property bool selectedAll
    iconName: selectedAll ? "select-none" : "select";
}

/*
 * Copyright (C) 2017 Stefano Verzegnassi
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License 3 as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see http://www.gnu.org/licenses/.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import Qt.labs.settings 1.0

Settings {
    property bool collapsedSidebar: false
    property int viewMethod: 0  // 0=List; 1=Grid
    property bool showHidden: false
    property int sortOrder: 0   // 0=Ascending; 1=Descending
    property int sortBy: 0  // 0=Name; 1=Date
    property int sidebarWidth: units.gu(20)
    property int gridSize: 1 // 0=S; 1=M; 2=L; 3=XL
    property int listSize: 1 // 0=S; 1=M; 2=L; 3=XL
    property bool darkTheme: false
}

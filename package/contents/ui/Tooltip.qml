import QtQuick 2.0
import QtQuick.Layouts 1.1
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0

ColumnLayout {

    property var busyList;
    property var dividerColor: Kirigami.Theme.textColor
    property var dividerOpacity: 0.1

    function truncateString(str, n) {
        if (str.length > n) {
            return str.slice(0, n) + "...";
        } else {
            return str;
        }
    }

    ColumnLayout {
        Layout.topMargin: PlasmaCore.Units.gridUnit / 2
        Layout.leftMargin: PlasmaCore.Units.gridUnit / 2
        Layout.bottomMargin: PlasmaCore.Units.gridUnit / 2
        Layout.rightMargin: PlasmaCore.Units.gridUnit / 2

        PlasmaExtras.Heading {
            id: tooltipMaintext
            level: 3
            elide: Text.ElideRight
            text: Plasmoid.metaData.name
        }

        PlasmaComponents3.Label {
            text: "Files are still being transferred...";
            opacity: .7
        }


        Repeater {
            model: busyList
            delegate: ColumnLayout {

                Rectangle {
                    Layout.preferredWidth: parent.width
                    height: 1
                    color: dividerColor
                    opacity: dividerOpacity
                }

                RowLayout {
                    ColumnLayout {
                                PlasmaComponents3.Label {
                                    text: truncateString(modelData.deviceName,30);
                                    opacity: 1
                                }
                                PlasmaComponents3.Label {
                                    text: truncateString(modelData.blockName,30);
                                    opacity: .7
                                }
                            }
                    //Item { implicitWidth: units.smallSpacing }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents3.Label {
                        text: "In flight: " + modelData.inFlight;
                        opacity: .7
                    }
                }
            }
        }
    }
}

import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents3

Item {
    id:root

    // Allow full view on the desktop
    Plasmoid.preferredRepresentation: plasmoid.location ===
                                    PlasmaCore.Types.Floating ?
                                    Plasmoid.fullRepresentation :
                                    Plasmoid.compactRepresentation

    property var statsList: []
    property var busyList: []

    Plasmoid.compactRepresentation: CompactRepresentation {
        // anchors.fill: parent
        PlasmaCore.ToolTipArea {
            anchors.fill: parent
            mainItem: Tooltip {
                busyList: root.busyList
            }
            visible: true
        }
    }

    Plasmoid.fullRepresentation: FullRepresentation {
        busyList: root.busyList
    }

    Plasmoid.status: busyList.length>0 ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus
    Plasmoid.busy: true

    property string statsString: ""
    
    // for file in /sys/block/*; do if [[ $(cat "${file}/removable") -eq 1 ]]; then; echo "$file $(cat ${file}/stat) $(cat ${file}/device/vendor) $(cat ${file}/device/model)"; fi; done
    property string statsCommand: "for file in /sys/block/*; do if [[ $(cat \"${file}/removable\") -eq 1 ]]; then echo \"$file $(cat ${file}/stat) $(cat ${file}/device/vendor) $(cat ${file}/device/model)\"; fi; done"
    //property string statsCommand: "for file in /sys/block/*; do echo \"$file $(cat ${file}/stat) $(cat ${file}/device/vendor) $(cat ${file}/device/model)\"; done"

    // Plasmoid.fullRepresentation: FullRepresentation {
    // }

    PlasmaCore.DataSource {
        id: getStats
        engine: "executable"
        connectedSources: []

        onNewData: {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            exited(sourceName, exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName) // cmd finished
        }

        function exec(cmd) {
            getStats.connectSource(cmd)
        }

        signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
    }


    Connections {
        target: getStats
        function onExited(cmd, exitCode, exitStatus, stdout, stderr) {
            console.log("CHECK STATS");
            console.log("cmd:",cmd);
            //console.log("exitCode:",exitCode);
            //console.log("stdout:",stdout);
            console.log("stderr:",stderr);
            statsString = stdout.trim(); //.replace('\n', '')
            statsList = getStatsList(statsString);
            busyList = getBusy(statsList);
        }
    }

    function getStatsList(statsString) {
        // column names from https://www.kernel.org/doc/Documentation/block/stat.txt
        var columnNames = ["blockName", "readIOs", "readMerges", "readSectors", "readTicks", "writeIOs", "writeMerges", "writeSectors", "writeTicks", "inFlight", "ioTicks", "timeInQueue", "discardIOs", "discardMerges", "discardSectors", "discardTicks", "flushIOs", "flushTicks"];

        var lines = statsString.split("\n");

        var statsList = [];

        // each line
        for (var i = 0; i < lines.length; i++){
            var columns = lines[i].split(/\s+/);
            console.log(lines[i].split(/\s+/));

            // init empty object
            var statsObject = {};

            // each stat column
            for (var j=0; j< columns.length; j++) {
                // add column data using the name
                statsObject[columnNames[j]] = columns[j];
            }

            var names = columns.slice(18).join(" ");

            if (names==="") {
                names=statsObject.blockName.split("/")
                names=names[names.length-1]
            }

            statsObject["deviceName"] = names;

            statsList.push(statsObject);
        }

        console.log(statsList.length);

        return statsList
    }

    function getBusy(statsList) {
        var busy = []
        for (let i = 0; i < statsList.length; i++) {
            if (statsList[i].inFlight > 0) {
                busy.push(statsList[i])
            }
        }
        return busy
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
    }

    

    Timer {
        interval: 1000;
        running: true;//autoReloadEnabled
        repeat: true;
        onTriggered: {
            getStats.exec(statsCommand);
        }
    }
}

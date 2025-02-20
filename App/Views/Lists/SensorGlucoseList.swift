//
//  SensorGlucoseList.swift
//  GlucoseDirectApp
//

import SwiftUI

struct SensorGlucoseList: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        Group {
            CollapsableSection(teaser: Text(getTeaser(sensorGlucoseValues.count)), header: Label("Sensor glucose values", systemImage: "sensor.tag.radiowaves.forward"), collapsed: true, collapsible: !sensorGlucoseValues.isEmpty) {
                if sensorGlucoseValues.isEmpty {
                    Text(getTeaser(sensorGlucoseValues.count))
                } else {
                    let smoothThreshold = Date().addingTimeInterval(-DirectConfig.smoothThresholdSeconds)

                    ForEach(sensorGlucoseValues) { sensorGlucose in
                        HStack {
                            Text(verbatim: sensorGlucose.timestamp.toLocalDateTime())
                            Spacer()

                            if let glucoseValue = sensorGlucose.smoothGlucoseValue?.toInteger(), sensorGlucose.timestamp < smoothThreshold, DirectConfig.smoothSensorGlucoseValues {
                                Text(verbatim: glucoseValue.asGlucose(glucoseUnit: store.state.glucoseUnit, withUnit: true, precise: isPrecise(glucoseValue: glucoseValue)))
                                    .if(glucoseValue < store.state.alarmLow || glucoseValue > store.state.alarmHigh) { text in
                                        text.foregroundColor(Color.ui.red)
                                    }
                            } else {
                                Text(verbatim: sensorGlucose.glucoseValue.asGlucose(glucoseUnit: store.state.glucoseUnit, withUnit: true, precise: isPrecise(glucoseValue: sensorGlucose.glucoseValue)))
                                    .if(sensorGlucose.glucoseValue < store.state.alarmLow || sensorGlucose.glucoseValue > store.state.alarmHigh) { text in
                                        text.foregroundColor(Color.ui.red)
                                    }
                            }
                        }
                    }.onDelete { offsets in
                        DirectLog.info("onDelete: \(offsets)")

                        let deletables = offsets.map { i in
                            (index: i, glucose: sensorGlucoseValues[i])
                        }

                        deletables.forEach { delete in
                            sensorGlucoseValues.remove(at: delete.index)
                            store.dispatch(.deleteSensorGlucose(glucose: delete.glucose))
                        }
                    }
                }
            }
        }
        .listStyle(.grouped)
        .onAppear {
            DirectLog.info("onAppear")
            self.sensorGlucoseValues = store.state.sensorGlucoseValues.reversed()
        }
        .onChange(of: store.state.sensorGlucoseValues) { glucoseValues in
            DirectLog.info("onChange")
            self.sensorGlucoseValues = glucoseValues.reversed()
        }
    }

    // MARK: Private

    @State private var sensorGlucoseValues: [SensorGlucose] = []

    private func getTeaser(_ count: Int) -> String {
        return count.pluralizeLocalization(singular: "%@ Entry", plural: "%@ Entries")
    }

    private func isPrecise(glucoseValue: Int) -> Bool {
        if store.state.glucoseUnit == .mgdL {
            return false
        }

        return glucoseValue.isAlmost(store.state.alarmLow, store.state.alarmHigh)
    }
}

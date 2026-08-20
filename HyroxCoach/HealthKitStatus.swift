// HealthKitStatus.swift
// Reports iPhone HealthKit availability and owns the minimal Cycle L1 authorization request.

import Combine
import HealthKit

final class HealthKitStatus: ObservableObject {
    @Published private(set) var isAvailable: Bool

    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
        self.isAvailable = HKHealthStore.isHealthDataAvailable()

        AppLog.health.info(
            "HealthKit availability checked: \(self.isAvailable, privacy: .public)"
        )
    }

    func requestAuthorization() async {
        AppLog.health.info("HealthKit read authorization request started")

        guard isAvailable else {
            AppLog.health.error("HealthKit is unavailable; authorization request skipped")
            return
        }

        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            AppLog.health.error("HealthKit heart-rate quantity type is unavailable")
            return
        }

        guard let activeEnergyType = HKObjectType.quantityType(
            forIdentifier: .activeEnergyBurned
        ) else {
            AppLog.health.error("HealthKit active-energy quantity type is unavailable")
            return
        }

        let readTypes: Set<HKObjectType> = [
            HKWorkoutType.workoutType(),
            heartRateType,
            activeEnergyType
        ]

        AppLog.health.info(
            "Requesting HealthKit read access for workout, heart rate, and active energy"
        )

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            AppLog.health.info("HealthKit read authorization request completed")
        } catch {
            AppLog.health.error(
                "HealthKit read authorization request failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }
}

//
//  UpdaterModel.swift
//  IOS IPA Install
//
//  Created by Julien Nicolas on 6/3/26.
//
import Foundation
import Observation
import Sparkle

/// Wraps Sparkle's standard updater so SwiftUI can drive "Check for Updates…"
/// and reflect whether a check is currently allowed.
@Observable
@MainActor
final class UpdaterModel {
    @ObservationIgnored private let controller: SPUStandardUpdaterController

    init() {
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var canCheckForUpdates: Bool {
        controller.updater.canCheckForUpdates
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}

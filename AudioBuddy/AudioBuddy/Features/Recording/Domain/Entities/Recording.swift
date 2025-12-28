//
//  Recording.swift
//  AudioBuddy
//
//  Created by Niraj Kale on 15/12/25.
//

import Foundation

struct Recording: Identifiable, Hashable {
    let id: UUID
    var title: String
    var date: Date
    var duration: TimeInterval
    var audioURL: URL
}

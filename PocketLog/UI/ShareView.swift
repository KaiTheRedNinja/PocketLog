//
//  ShareView.swift
//  PocketLog
//
//  Created by Kai Quan Tay on 17/11/26.
//

import SwiftUI

struct ShareView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIActivityViewController

    var activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // i think we can leave this empty?
        // i cant find a way to set the activity items after creation
    }
}

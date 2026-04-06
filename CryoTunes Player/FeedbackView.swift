//
//  FeedbackView.swift
//  CryoTunes Player
//
//  Created by Michael Fluharty on 4/6/26.
//

import SwiftUI
import MessageUI

struct FeedbackView: View {
    let appName: String
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackType: FeedbackType = .bug
    @State private var feedbackText = ""
    @State private var showingMailSheet = false
    @State private var showingMailUnavailable = false

    private let iceBlue = Color(red: 0.65, green: 0.82, blue: 0.95)
    private let iceDark = Color(red: 0.12, green: 0.18, blue: 0.28)
    private let iceBorder = Color(red: 0.35, green: 0.55, blue: 0.75)
    private let iceAccent = Color(red: 0.5, green: 0.78, blue: 0.95)

    enum FeedbackType: String, CaseIterable {
        case bug = "Bug Report"
        case feature = "Feature Request"
    }

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "v\(v) (\(b))"
    }

    private var deviceInfo: String {
        let device = UIDevice.current
        var sysinfo = utsname()
        uname(&sysinfo)
        let model = withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(validatingCString: $0) ?? "Unknown" }
        }
        let storage: String = {
            guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
                  let free = attrs[.systemFreeSize] as? Int64 else { return "Unknown" }
            return ByteCountFormatter.string(fromByteCount: free, countStyle: .file)
        }()
        return """

        --- Device Info ---
        App: \(appName) \(version)
        Device: \(model)
        System: \(device.systemName) \(device.systemVersion)
        Storage Available: \(storage)
        Locale: \(Locale.current.identifier)
        """
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Feedback Type", selection: $feedbackType) {
                        ForEach(FeedbackType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextEditor(text: $feedbackText)
                        .font(.system(size: 18, design: .monospaced))
                        .frame(minHeight: 200)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .background(iceDark)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(iceBorder.opacity(0.3), lineWidth: 1)
                        )
                        .foregroundStyle(.white)

                    if feedbackText.isEmpty {
                        Text(feedbackType == .bug
                             ? "Describe what happened and what you expected..."
                             : "Describe the feature you'd like to see...")
                            .font(.system(size: 18, design: .monospaced))
                            .foregroundStyle(iceBorder.opacity(0.4))
                            .allowsHitTesting(false)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 28)
                            .padding(.top, -190)
                    }

                    Button {
                        if MFMailComposeViewController.canSendMail() {
                            showingMailSheet = true
                        } else {
                            showingMailUnavailable = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 18))
                            Text("Send")
                                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(feedbackText.isEmpty ? iceBorder.opacity(0.3) : iceAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(feedbackText.isEmpty)
                }
                .padding(16)
            }
            .background(Color(red: 0.06, green: 0.09, blue: 0.16))
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 18, design: .monospaced))
                        .foregroundStyle(iceAccent)
                }
            }
            .sheet(isPresented: $showingMailSheet) {
                MailComposeView(
                    subject: "\(appName) \(feedbackType.rawValue) — \(version)",
                    body: feedbackText + "\n\n" + deviceInfo,
                    recipient: "michael.fluharty@mac.com"
                )
            }
            .alert("Mail Not Available", isPresented: $showingMailUnavailable) {
                Button("OK") { }
            } message: {
                Text("Please configure a mail account in Settings, or email michael.fluharty@mac.com directly.")
            }
        }
    }
}

struct MailComposeView: UIViewControllerRepresentable {
    let subject: String
    let body: String
    let recipient: String
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients([recipient])
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(dismiss: dismiss) }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction
        init(dismiss: DismissAction) { self.dismiss = dismiss }
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            dismiss()
        }
    }
}

    //
    //  DocumentViewController.swift
    //  DJ Set Analyzer
    //
    //  Created by Sebastiaan Hols on 22/11/2021.
    //

import UIKit
import CoreHaptics

class DocumentViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let analyzer : Analyzer = Analyzer()
    
    static let cellID = "TracksTableCell"
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var documentNameLabel: UILabel!
    
    @IBOutlet weak var progressBar: UIProgressView!
    
    @IBOutlet weak var progressLabel: UILabel!
    
    var selectedIndex = IndexPath(row: -1, section: 0)
    
    var previousSelectedIndex = IndexPath(row: -1, section: 0)
    
    let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    let noHitsView = UIImageView()
    
    let noHits = UIImage(systemName: "xmark.circle")
    
    let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
    
    let copiedImage = UIImage(systemName: "doc.on.clipboard.fill")
    
    let musicNote = UIImage(systemName: "music.note")
    
    @IBAction func dismissDocumentViewController() {
        dismiss(animated: true) {
            self.document?.close(completionHandler: nil)
            self.analyzer.reset()
        }
    }
    
    var document: UIDocument?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        notificationFeedbackGenerator.prepare()
        loadingIndicator.startAnimating()
        tableView.backgroundView = loadingIndicator
        noHitsView.contentMode = .center
        let config = UIImage.SymbolConfiguration(pointSize: 64)
        noHitsView.preferredSymbolConfiguration = config
        noHitsView.image = noHits
        
            // Access the document
        document?.open(completionHandler: { [self] (success) in
            if success {
                if let fileURL = self.document?.fileURL {
                        // Display the content of the document, e.g.:
                    self.documentNameLabel.text = fileURL.lastPathComponent
                    self.analyzer.active = true
                    self.analyzer.run(fileURL)
                    analyzer.updateProgress = { progress in
                        switch progress.state {
                            case .splitting:
                                progressBar.isHidden = false
                                progressLabel.text = "Splitting the track"
                                break
                            case .analyzing:
                                if !analyzer.hits.isEmpty {
                                    loadingIndicator.isHidden = true
                                }
                                progressLabel.text = "Analyzing audio samples"
                                break
                            case .done:
                                progressLabel.text = "\(analyzer.hits.count) tracks recognized"
                                progressBar.progressTintColor = .systemGreen
                                loadingIndicator.isHidden = true
                                if analyzer.hits.count == 0 {
                                    tableView.backgroundView = noHitsView
                                }
                                break
                        }
                        progressBar.setProgress(progress.amount, animated: true)
                    }
                    analyzer.refreshTable = {
                        
                        UIView.transition(with: tableView,
                                          duration: 0.35,
                                          options: .transitionCrossDissolve,
                                          animations:
                                            { () -> Void in
                            self.tableView.reloadData()
                        },
                                          completion: nil);
                    }
                }
            } else {
                    // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
                notificationFeedbackGenerator.notificationOccurred(.error)
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return analyzer.hits.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellID, for: indexPath) as? TrackTableCell else {
            fatalError("Unable to dequeue TrackTableCell")
        }
        let hit = analyzer.hits[indexPath.row]
        let (h,m,s) = secondsToHoursMinutesSeconds(Int(hit.matchOffset))
        cell.trackTitle.text = "\(hit.title!) @ \(String(format: "%02d:%02d:%02d", h, m, s))"
        cell.trackArtist.text = hit.artist
        if selectedIndex == indexPath {
            cell.cellImage.image = copiedImage
            cell.cellImage.tintColor = .systemGreen
        } else {
            cell.cellImage.image = musicNote
            cell.cellImage.tintColor = .systemBlue
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = "\(analyzer.hits[indexPath.row].artist!) \(analyzer.hits[indexPath.row].title!)"
        previousSelectedIndex = selectedIndex
        selectedIndex = indexPath
        let refreshRows = [previousSelectedIndex, selectedIndex].filter { $0.row != -1 }
        tableView.reloadRows(at: refreshRows, with: .automatic)
        notificationFeedbackGenerator.notificationOccurred(.success)
    }
    
    func secondsToHoursMinutesSeconds(_ seconds: Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
}

class TrackTableCell : UITableViewCell {
    @IBOutlet weak var trackTitle: UILabel!
    @IBOutlet weak var trackArtist: UILabel!
    @IBOutlet weak var cellImage: UIImageView!
}


enum ProgresState {
    case splitting
    case analyzing
    case done
}

struct Progress {
    let state: ProgresState
    let amount: Float
}


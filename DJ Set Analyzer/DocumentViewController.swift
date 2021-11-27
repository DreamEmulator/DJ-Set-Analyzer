    //
    //  DocumentViewController.swift
    //  DJ Set Analyzer
    //
    //  Created by Sebastiaan Hols on 22/11/2021.
    //

import UIKit

class DocumentViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let analyzer : Analyzer = Analyzer()
    
    static let cellID = "TracksTableCell"
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var documentNameLabel: UILabel!
    
    @IBOutlet weak var progressBar: UIProgressView!
    
    @IBOutlet weak var progressLabel: UILabel!
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    @IBAction func dismissDocumentViewController() {
        dismiss(animated: true) {
            self.document?.close(completionHandler: nil)
            self.analyzer.reset()
        }
    }
    
    var document: UIDocument?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadingIndicator.startAnimating()
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
                                progressLabel.isHidden = true
                                progressBar.isHidden = true
                                break
                        }
                        progressBar.setProgress(progress.amount, animated: true)
                    }
                    analyzer.refreshTable = {
                        tableView.reloadData()
                    }
                }
            } else {
                    // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
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
        cell.trackTitle.text = analyzer.hits[indexPath.row].title
        cell.trackArtist.text = analyzer.hits[indexPath.row].artist
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = "\(analyzer.hits[indexPath.row].artist!) \(analyzer.hits[indexPath.row].title!)"
    }
    
}

class TrackTableCell : UITableViewCell {
    @IBOutlet weak var trackTitle: UILabel!
    @IBOutlet weak var trackArtist: UILabel!
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

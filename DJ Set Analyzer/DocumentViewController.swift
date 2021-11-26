    //
    //  DocumentViewController.swift
    //  DJ Set Analyzer
    //
    //  Created by Sebastiaan Hols on 22/11/2021.
    //

import UIKit

class DocumentViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    static let cellID = "TracksTableCell"
    @IBOutlet weak var tableView: UITableView!
    
    let analyzer : Analyzer = Analyzer()
    
    @IBOutlet weak var documentNameLabel: UILabel!
    
    var document: UIDocument? {
        didSet {
            analyzer.run(self.document!.fileURL)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
            // Access the document
        document?.open(completionHandler: { [self] (success) in
            if success {
                    // Display the content of the document, e.g.:
                self.documentNameLabel.text = self.document?.fileURL.lastPathComponent
                self.analyzer.active = true
                analyzer.update = {
                    tableView.reloadData()
                    print("UPDATED")
                }
            } else {
                    // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
            }
        })
    }
    
    @IBAction func dismissDocumentViewController() {
        dismiss(animated: true) {
            self.document?.close(completionHandler: nil)
            self.analyzer.active = false
        }
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

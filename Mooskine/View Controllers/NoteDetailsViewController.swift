//
//  NoteDetailsViewController.swift
//  Mooskine
//
//  Created by Josh Svatek on 2017-05-31.
//  Copyright © 2017 Udacity. All rights reserved.
//

import UIKit
import CoreData

class NoteDetailsViewController: UIViewController {
    /// A text view that displays a note's text
    @IBOutlet weak var textView: UITextView!

    /// The note being displayed and edited
    var note: Note!
    
    // IMPLICITLY UNWRAPPED DATACONTROLLER PROPERTY
    var dataController: DataController!
    
    /// A closure that is run when the user asks to delete the current note
    var onDelete: (() -> Void)?

    /// A date formatter for the view controller's title text
    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let creationDate = note.creationDate {
            // OPTIONAL UNWRAPPING FOR CREATION DATE
            navigationItem.title = dateFormatter.string(from: creationDate)

        }
        textView.text = note.text
    }

    @IBAction func deleteNote(sender: Any) {
        presentDeleteNotebookAlert()
    }
}

// -----------------------------------------------------------------------------
// MARK: - Editing

extension NoteDetailsViewController {
    func presentDeleteNotebookAlert() {
        let alert = UIAlertController(title: "Delete Note", message: "Do you want to delete this note?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: deleteHandler))
        present(alert, animated: true, completion: nil)
    }

    func deleteHandler(alertAction: UIAlertAction) {
        onDelete?()
    }
}

// -----------------------------------------------------------------------------
// MARK: - UITextViewDelegate

extension NoteDetailsViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        // MANAGED OBJECTS HOLD A REFERENCE TO THEIR ASSOCIATED VIEW CONTEXT
        // try? SAVING THE CONTEXT TO PERSIST THE APP'S UNSAVED CHANGES
        note.text = textView.text
        do {
//            try note.managedObjectContext?.save()
            try dataController.viewContext.save()
        } catch {
            let alert = UIAlertController(title: "Cannot save note", message: "Your note cannot be saved at the moment. Please try again later.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
        }
    }
}

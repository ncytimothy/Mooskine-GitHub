//
//  NotesListViewController.swift
//  Mooskine
//
//  Created by Josh Svatek on 2017-05-31.
//  Copyright © 2017 Udacity. All rights reserved.
//

import UIKit
import CoreData

class NotesListViewController: UIViewController, UITableViewDataSource {
    /// A table view that displays a list of notes for a notebook
    @IBOutlet weak var tableView: UITableView!

    /// The notebook whose notes are being displayed
    var notebook: Notebook!
    
    // EMPTY NOTES ARRAY TO COMMUNICATE WITH CORE DATA
    var notes: [Note] = []
    
    // Data Controller Propety from AppDelegate.swift
    // Implicitly unwrapped data controller property
    var dataController: DataController!
    
    /// A date formatter for date text in note cells
    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = notebook.name
        navigationItem.rightBarButtonItem = editButtonItem
        updateEditButtonState()
        
        // CREATE FETCH REQUEST
        
        // FETCH REQUEST
        // SELECTS INTERESTED DATA
        // LOADS THE DATA FROM PERSISTENT STORE INTO THE CONTEXT
        // MUST BE CONFIGURED WITH AN ENTITY TYPE
        // CAN OPTIONALLY INCLUDE FILTERING AND SORTING
        
        // 1. CREATE FETCH REQUEST
        // FETCH REQUESTS ARE GENERIC TYPES, SO YOU SPECIFY THE TYPE PARAMETER
        // SPECIFYING THE TYPE PARAMETER WILL MAKE THE FETCH REQUEST
        // WORK WITH A SPECIFIC MANAGED OBJECT SUBCLASS
        // CALL THE TYPE FUNCTON FETCH REQUEST ON THAT SUBCLASS
        // Pin.fetchRequest() returns a fetch request initialized with the entity
        
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        
        // 2. CONFIGURE FETCH REQUEST
        // ADD NSPredicate TO FILTER OUT THE NOTES FOR A SPECIFIC NOTEBOOK
        // A. NOTE THAT THE RELATIONSHIP IN THE DATA MODEL GIVES US THE .note PROPERTY
        // FROM NOTEBOOK
        // B. CREATE AND SET THE SORT DESCRIPTOR TO creationDate
        // TODO: Understand where the note property comes from (specifically, which notebook?)
        if let notebook = notebook {
            let predicate = NSPredicate(format: "notebook == %@", notebook)
            // SET THE FETCH REQUEST'S PREDICATE TO THE OUR SPEFICIFED PREDICATE (CURRENT NOTEBOOK)
            fetchRequest.predicate = predicate
        }
        
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // 3. PERFORM THE FETCH REQUEST
        // ASK A CONTEXT TO EXECUTE THE REQUEST
        // ASK DATA CONTROLLER'S VIEW CONTEXT (PERSISTENT CONTROLLER'S VIEW CONTEXT)
        // .fetch() CAN THROW AN ERROR
        // SAVE THE RESULTS ONLY IF THE FETCH IS SUCCESSFUL
        // USE try? TO CONVERT THE ERROR INTO AN OPTIONAL
        
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            notes = result
        }
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: false)
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
        // RELOAD DATA ONCE THE TABLE VIEW WILL APPEAR
        tableView.reloadData()
    }

    // -------------------------------------------------------------------------
    // MARK: - Actions

    @IBAction func addTapped(sender: Any) {
        addNote()
    }

    // -------------------------------------------------------------------------
    // MARK: - Editing

    // Adds a new `Note` to the end of the `notebook`'s `notes` array
    func addNote() {
        /**
         * MAKE CHANGES IN A CONTEXT AND THEN ASK THE CONTEXT TO SAVE THE CHANGES
         * TO THE PERSISTENT STORE
         */
        
        // NOTE IS AN MANAGED OBJECT
        // WE WILL USE CONVENIENCE INITIALIZER FROM MANAGED OBJECTS
        // WE CAN ASSOCIATE THE OBJECT WITH A CONTEXT
        
        // 1. INSTANTIATE A MANAGED OBJECT
        let note = Note(context: dataController.viewContext)
        
        // 2. CONFIGURE THE NOTE MANAGED OBJECT
        note.text = "New Note"
       // CREATION DATE ADDED IN INITIALIZATION (in Note+Extensions)
        note.notebook = notebook
        
        // 3. SAVE THE NOTE ASSOCIATED WITH A CONTEXT
        // AS SOON AS THE NOTEBOOK IS CREATED, WE WILL ASK THE CONTEXT TO SAVE THE NOTEBOOK INTO THE PERSISTENT STORE
        // YOU CAN USE try? TO CONVERT THE ERROR INTO AN OPTIONAL
        // IN A PRODUCTION APP, YOU WILL WANT TO NOTIFY THE USER IF THE DATA HASN'T BEEN SAVED
    
        do {
            try dataController.viewContext.save()
        } catch {
            let alert = UIAlertController(title: "Cannote add note", message: "Your note cannot be added at the moment. Please try again later.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
        }
        
        // 4. UPDATE UI
        notes.insert(note, at: 0)
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
        updateEditButtonState()
    }

    // Deletes the `Note` at the specified index path
    func deleteNote(at indexPath: IndexPath) {
        // 1. GET A REFERENCE TO THE NOTE TO DELETE
        // USING note(at:) "index path" helper function
        let noteToDelete = note(at: indexPath)
        
        // 2. CALL THE CONTEXT'S DELETE FUNCTION PASSING IN noteToDelete
        dataController.viewContext.delete(noteToDelete)
        
        // 3. TRY TO SAVE THE CHANGE TO THE PERSISTENT CONTROLLER
        do {
            try dataController.viewContext.save()
        } catch {
            let alert = UIAlertController(title: "Cannot delete note", message: "Your note cannot be deleted at the moment. Please try again later", preferredStyle: .alert)
            let okAlert = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAlert)
        }
        
        // 4. REMOVE THE NOTE FROM THE NOTES ARRAY
        notes.remove(at: indexPath.row)
        
        tableView.deleteRows(at: [indexPath], with: .fade)
        if numberOfNotes == 0 {
            setEditing(false, animated: true)
        }
        updateEditButtonState()
    }

    func updateEditButtonState() {
        navigationItem.rightBarButtonItem?.isEnabled = numberOfNotes > 0
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }

    // -------------------------------------------------------------------------
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfNotes
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aNote = note(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: NoteCell.defaultReuseIdentifier, for: indexPath) as! NoteCell

        // Configure cell
        cell.textPreviewLabel.text = aNote.text
        // OPTIONALLY UNWRAP aNote.creationDate
        if let creationDate = aNote.creationDate {
            cell.dateLabel.text = dateFormatter.string(from: creationDate)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete: deleteNote(at: indexPath)
        default: () // Unsupported
        }
    }

    // Helpers
    // UPDATE FUNCTION AND PROPERTIES TO USE FILE DEFINED NOTES ARRAY
    var numberOfNotes: Int { return notes.count }

    func note(at indexPath: IndexPath) -> Note {
        return notes[indexPath.row]
    }

    // -------------------------------------------------------------------------
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If this is a NoteDetailsViewController, we'll configure its `Note`
        // and its delete action
        if let vc = segue.destination as? NoteDetailsViewController {
            if let indexPath = tableView.indexPathForSelectedRow {
                vc.note = note(at: indexPath)
                // PASSING THE DATA CONTROLLER PROPERTY
                vc.dataController = dataController

                vc.onDelete = { [weak self] in
                    if let indexPath = self?.tableView.indexPathForSelectedRow {
                        self?.deleteNote(at: indexPath)
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
}

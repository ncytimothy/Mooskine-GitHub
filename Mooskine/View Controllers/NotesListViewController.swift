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
    
    // FETCHED RESULTS CONTROLLER WILL PERSIST OVER THE LIFETIME OF THE VIEW CONTROLLER
    // NEED TO SPECIFY THE MANAGED OBJECT (GENERIC TYPE)
    var fetchedResultsController: NSFetchedResultsController<Note>!
    
    // Data Controller Propety from AppDelegate.swift
    // Implicitly unwrapped data controller property
    var dataController: DataController!
    
    /// A date formatter for date text in note cells
    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()
    
    fileprivate func setUpFetchedResultsController() {
        // TO INSTANTIATE A FETCHED RESULTS CONTROLLER
        // WE NEED TO TELL IT WHICH DATA OBJECTS TO FETCH AND TRACK
        // WE NEED TO DESCRIBE THE DATA WE WANT USING A FETCH REQUEST
        
        // WE CAN USE THE SAME FETCH REQUEST FROM BEFORE
        // GENERALLY, FETCH REQUESTS DO NOT HAVE TO BE SORTED
        // IMPORTANT: ANY FETCH REQUESTS USING A FETCHED RESULTS CONTROLLER MUST BE SORTED
        // THIS IS PRESERVE CONSISTENT ORDERING
        
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
        // fetchRequest.sortDescriptors property takes an array of sort descriptors
        // NOTICE THAT THE ORDER IN WHICH THE FETCH HAPPENS IS SPECIFIED BY THE SORT DESCRIPTORS
        // TODO: Understand where the note property comes from (specifically, which notebook?)
        
        // A. PICKING THE RIGHT NOTEBOOK
        if let notebook = notebook {
            let predicate = NSPredicate(format: "notebook == %@", notebook)
            fetchRequest.predicate = predicate
        }
        
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // 2. INSTANTIATE THE FETCHED RESULTS CONTROLLER USING THE FETCH REQUEST
        // sectionNameKeyPath: divides data into sections
        // FETCHED RESULTS CONTROLLER CAN AVOID REPETITIVE WORK BY CACHING SECTION AND ORDERING INFORMATION
        // THIS WILL IMPROVE PERFORMANCE
        // IF YOU SPECIFY A cacheName, CACHING WILL HAPPEN AUTOMATICALLY AND THE CACHE WILL PERSIST
        // BETWEEN SESSIONS
        // CACHE UPDATES ITSELF AUTOMATICALLY WHEN SECTION OR ORDERING INFORMATION CHANGES
        // WITH MULTIPLE FETCHED RESULTS CONTROLLERS, EACH SHOULD HAVE THEIR OWN CACHE NAME
        
        // IF YOU EVER CHANGE THE FETCH RESULT OF A FETCHED RESULTS CONTROLLER
        // YOU SHOULD DELETE THE CACHE MANUALLY FIRST
        // USE deleteCache(withName:)
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(notebook)--notes")
        
        // 3. SET THE FETCHED RESULTS CONTROLLER DELEGATE PROPERTY TO SELF
        // FETCHED RESULTS CONTROLLER TRACKS CHANGES
        // TO RESPONSE TO THOSE CHANGES, NEED TO IMPLEMENT SOME DELEGATE METHODS
        fetchedResultsController.delegate = self
        
        // 4. PERFORM FETCH TO LOAD DATA AND START TRACKING
        do {
            try fetchedResultsController.performFetch()
        } catch {
            // FATAL ERROR IS THROWN IF FETCH FAILS
            fatalError("The fetch cannot be performed: \(error.localizedDescription)")
        }
        
        // 5. REMOVE THE FETCHED RESULTS CONTROLLER WHEN THE VIEW DISAPPEARS
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = notebook.name
        navigationItem.rightBarButtonItem = editButtonItem
        setUpFetchedResultsController()
        updateEditButtonState()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // FETCHED RESULTS CONTROLLER SETUP
        setUpFetchedResultsController()
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: false)
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
        // RELOAD DATA ONCE THE TABLE VIEW WILL APPEAR
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // NEED TO REMOVE FETCHED RESULTS CONTROLLER WHEN VIEW DISAPPEARS
        // TO UNSUBSCRIBE TO MANAGED OBJECT CONTEXT CHANGES AND SAVES NOTIFICATIONS
        fetchedResultsController = nil
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
        // REPLACE UPDATE UI CODE TO EXTENSION, WHERE THE FETCHED RESULTS HANDLES THE CHANGES IN
        // THE MODEL, AND THE CHANGES IN THE UI
        
    }

    // Deletes the `Note` at the specified index path
    func deleteNote(at indexPath: IndexPath) {
        // 1. GET A REFERENCE TO THE NOTEBOOK TO DELETE
        // Using note(at:) "index path" helper function (PREVIOUSLY)
        // NOW USE THE FETCHED RESULTS CONTROLLER .object(at:) indexPath method
        let noteToDelete = fetchedResultsController.object(at: indexPath)
        
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
        
        // 4. UPDATE UI
        // REPLACE UPDATE UI CODE TO EXTENSION, WHERE THE FETCHED RESULTS HANDLES THE CHANGES IN
        // THE MODEL, AND THE CHANGES IN THE UI
    }

    func updateEditButtonState() {
        if let sections = fetchedResultsController.sections {
            navigationItem.rightBarButtonItem?.isEnabled = sections[0].numberOfObjects > 0
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }

    // -------------------------------------------------------------------------
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // USE FETCHED RESULTS CONTROLLER'S sections PROPERTY TO FIND OUT
        // HOW MANY SECTIONS THE DATA HAS
        // THE SECTIONS PROPERTY IS OPTIONAL
        // NIL-COALESCING OPERATOR
        // GET THE NUMBER OF SECTIONS FROM PERSISTENT STORE, OTHERWISE 1
        print("numberOfSections")
        return fetchedResultsController.sections?.count ?? 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // REFERENCE A SPECIFIC SECTION
        // EACH SECTION HAS A PROPERTY .numberOfObjects
        // WE WILL RETURN THE NUMBER OF OBJECTS, OTHERWISE 0
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // GET THE NOTEBOOK FROM THE FETCHED RESULTS CONTROLLER (SPECIFICED WITH AN INDEX PATH)
        let aNote = fetchedResultsController.object(at: indexPath)
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

    // -------------------------------------------------------------------------
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If this is a NoteDetailsViewController, we'll configure its `Note`
        // and its delete action
        if let vc = segue.destination as? NoteDetailsViewController {
            if let indexPath = tableView.indexPathForSelectedRow {
                // NOTE PASSING TO THE NoteDetailsViewController
                // USE FETCH RESULTS VIEW CONTROLLER'S .object(at:) method
                vc.note = fetchedResultsController.object(at: indexPath)
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

extension NotesListViewController: NSFetchedResultsControllerDelegate {
    
    // 1. CONFIGURE THE UI WHEN DATA MODEL DID CHANGE
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        // Notifies the receiver that a fetched object has been changed due to an add, remove, move, or update.
        // type is an enum
        
        // ONLY IMPLEMENT INSERT AND DELETE
        
        switch type {
        case .insert:
            // INSERT THE ADDED OBJECT TO THE TABLE VIEW WITH newIndexPath
            tableView.insertRows(at: [newIndexPath!], with: .fade)
            break
        case .delete:
            // indexPath PARAMETER CONTAINS THE INDEX PATH OF THE ROW TO DELETE
            tableView.deleteRows(at: [indexPath!], with: .fade)
            break
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
        
    }
    
    // controller(didChange:atSectionIndex:)
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        print("didChange, ")
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert: tableView.insertSections(indexSet, with: .fade)
        case .delete: tableView.deleteSections(indexSet, with: .fade)
        case .update, .move:
            fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
        }
    }
        
    // 2. BEGIN UI UPDATES WHEN DATA MODEL WILL CHANGE CONTENT
    // TABLE VIEW CHANGES NEED TO BE BOOKENDED BETWEEN .beginUpdates() AND .endUpdates() CALLS
    // REACTIVE TABLE VIEW THAT AUTOMATICALLY RESPONSES TO INSERTS AND DELETES
        
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // GETS CALLED BEFORE A BATCH OF UPDATES
        // BEGIN UPDATES IS IMPORTANT TO TRACK CHANGES IN THE MODEL AND REACTIVELY UPDATE THE TABLE VIEW
        // THIS IS REFERRING TO THE TABLEVIEW'S DATA SOURCE
        tableView.beginUpdates()
    }
        
    // 3. END UI UPDATES WHEN DATA MODEL DID CHANGE CONTENT
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // END UPDATES IS IMPORTANT TO TRACK CHANGES IN THE MODEL AND REACTIVELY UPDATE THE TABLE VIEW
        // THIS IS REFERRING TO THE TABLEVIEW'S DATA SOURCE
        tableView.endUpdates()
    }
}



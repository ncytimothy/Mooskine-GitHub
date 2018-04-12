//
//  NotebooksListViewController.swift
//  Mooskine
//
//  Created by Josh Svatek on 2017-05-31.
//  Copyright © 2017 Udacity. All rights reserved.
//

import UIKit
import CoreData

class NotebooksListViewController: UIViewController, UITableViewDataSource {
    /// A table view that displays a list of notebooks
    @IBOutlet weak var tableView: UITableView!

    
    // Data Controller property from AppDelegate.swift
    var dataController: DataController!
    
    // FETCHED RESULTS CONTROLLER WILL PERSIST OVER THE LIFETIME OF THE VIEW CONTROLLER
    // NEED TO SPECIFY THE MANAGED OBJECT (GENERIC TYPE)
    var fetchedResultsController: NSFetchedResultsController<Notebook>!
    
    // FETCH REQUEST
    // SELECTS INTERESTED DATA
    // LOADS THE DATA FROM PERSISTENT STORE INTO THE CONTEXT
    // MUST BE CONFIGURED WITH AN ENTITY TYPE
    // CAN OPTIONALLY INCLUDE FILTERING AND SORTING
    
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
        
        let fetchRequest: NSFetchRequest<Notebook> = Notebook.fetchRequest()
        
        // 2. CONFIGURE FETCH REQUEST BY ADDING A SORT RULE
        // fetchRequest.sortDescriptors property takes an array of sort descriptors
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // 2. INSTANTIATE THE FETCHED RESULTS CONTROLLER USING THE FETCH REQUEST
        // sectionNameKeyPath: divides data into sections
        // cacheName: LATER
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "toolbar-cow"))
        navigationItem.rightBarButtonItem = editButtonItem
        
        setUpFetchedResultsController()
        
        // 5. IMPLEMENT DELEGATE METHODS FOR FETCHED RESULTS CONTROLLER TO TRACK CHANGES
        // (IN EXTENSION)
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: false)
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // NEED TO REMOVE FETCHED RESULTS CONTROLLER WHEN VIEW DISAPPEARS
        // TO UNSUBSCRIBE TO MANAGED OBJECT CONTEXT CHANGES AND SAVES NOTIFICATIONS
        fetchedResultsController = nil
    }

    // -------------------------------------------------------------------------
    // MARK: - Actions

    @IBAction func addTapped(sender: Any) {
        presentNewNotebookAlert()
    }

    // -------------------------------------------------------------------------
    // MARK: - Editing

    /// Display an alert prompting the user to name a new notebook. Calls
    /// `addNotebook(name:)`.
    func presentNewNotebookAlert() {
        let alert = UIAlertController(title: "New Notebook", message: "Enter a name for this notebook", preferredStyle: .alert)

        // Create actions
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] action in
            if let name = alert.textFields?.first?.text {
                self?.addNotebook(name: name)
            }
        }
        saveAction.isEnabled = false

        // Add a text field
        alert.addTextField { textField in
            textField.placeholder = "Name"
            NotificationCenter.default.addObserver(forName: .UITextFieldTextDidChange, object: textField, queue: .main) { notif in
                if let text = textField.text, !text.isEmpty {
                    saveAction.isEnabled = true
                } else {
                    saveAction.isEnabled = false
                }
            }
        }

        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        present(alert, animated: true, completion: nil)
    }

    /// Adds a new notebook to the end of the `notebooks` array
    func addNotebook(name: String) {
        /**
        * MAKE CHANGES IN A CONTEXT AND THEN ASK THE CONTEXT TO SAVE THE CHANGES
        * TO THE PERSISTENT STORE
        */
        
        // NOTEBOOK IS AN MANAGED OBJECT
        // WE WILL USE CONVENIENCE INITIALIZER FROM MANAGED OBJECTS
        // WE CAN ASSOCIATE THE OBJECT WITH A CONTEXT
        // 1. INSTANTIATE A MANAGED OBJECT
        let notebook = Notebook(context: dataController.viewContext)
        
        // 2..CONFIGURE THE NOTEBOOK MANAGED OBJECT
        notebook.name = name
        // CREATION DATE ADDED IN THE NOTEBOOK'S INITIALIZATION (in Notebook+Extensions)
        
        // 3. SAVE THE NOTE ASSOCIATED WITH A CONTEXT
        // AS SOON AS THE NOTEBOOK IS CREATED, WE WILL ASK THE CONTEXT TO SAVE THE NOTEBOOK INTO THE PERSISTENT STORE
        // YOU CAN USE try? TO CONVERT THE ERROR INTO AN OPTIONAL
        // IN A PRODUCTION APP, YOU WILL WANT TO NOTIFY THE USER IF THE DATA HASN'T BEEN SAVED
   
        do {
            try dataController.viewContext.save()
        } catch {
            let alert = UIAlertController(title: "Cannot save notebook", message: "Your notebook cannot be saved at the moment. Please try again later.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
        }
     
        // 4. UPDATE UI
        
    }
    

    /// Deletes the notebook at the specified index path
    func deleteNotebook(at indexPath: IndexPath) {
        // 1. GET A REFERENCE TO THE NOTEBOOK TO DELETE
        // Using notebook(at:) "index path" helper function (PREVIOUSLY)
        // NOW USE THE FETCHED RESULTS CONTROLLER .object(at:) indexPath method
        let notebookToDelete = fetchedResultsController.object(at: indexPath)
        
        // 2. CALL THE CONTEXT'S DELETE FUNCTON PASSSING IN notebookToDelete
        dataController.viewContext.delete(notebookToDelete)
        
        // 3. TRY TO SAVE THE CHANGE TO THE PERSISTENT STORE
        do {
            try dataController.viewContext.save()
        } catch {
            let alert = UIAlertController(title: "Cannot delete notebook", message: "Your notebook cannot be deleted at the moment. Please try again later.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
        }
    }

    func updateEditButtonState() {
        
        // GET THE NOTEBOOKS COUNT FROM THE FETCHED RESULTS CONTROLLER
        // CONDITIONALLY UNWRAP THE sections PROPERTY
        // CHECK .numberOfObjects IN THE FIRST (AND ONLY) SECTION
        
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
        let aNotebook = fetchedResultsController.object(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: NotebookCell.defaultReuseIdentifier, for: indexPath) as! NotebookCell

        // Configure cell
        cell.nameLabel.text = aNotebook.name
        if let count = aNotebook.notes?.count {
            // OPTIONAL UNWRAPPING FOR NOTEBOOKS PAGES COUNT
            let pageString = count == 1 ? "page" : "pages"
            cell.pageCountLabel.text = "\(count) \(pageString)"
        }

        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete: deleteNotebook(at: indexPath)
        default: () // Unsupported
        }
    }

    // -------------------------------------------------------------------------
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If this is a NotesListViewController, we'll configure its `Notebook`
        if let vc = segue.destination as? NotesListViewController {
            if let indexPath = tableView.indexPathForSelectedRow {
                // NOTEBOOK PASSING TO THE NotesListViewVC
                // USE FETCH RESULTS VIEW CONTROLLER'S .object(at:) method
                vc.notebook = fetchedResultsController.object(at: indexPath)
            }
            // PASSING THE dataController from NotebooksListViewVC to NotesListViewVC
            vc.dataController = dataController
        }
    }
}

extension NotebooksListViewController: NSFetchedResultsControllerDelegate {
    
    // TABLE VIEW CHANGES NEED TO BE BOOKENDED BETWEEN .beginUpdates() AND .endUpdates() CALLS
    // REACTIVE TABLE VIEW THAT AUTOMATICALLY RESPONSES TO INSERTS AND DELETES
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // GETS CALLED BEFORE A BATCH OF UPDATES
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
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
        default:
            break
        }
        
    }
    
}

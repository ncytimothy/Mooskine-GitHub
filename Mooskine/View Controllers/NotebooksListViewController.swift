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

    /// The `Notebook` objects being presented
    var notebooks: [Notebook] = []
    
    // Data Controller property from AppDelegate.swift
    var dataController: DataController!
    
    // FETCH REQUEST
    // SELECTS INTERESTED DATA
    // LOADS THE DATA FROM PERSISTENT STORE INTO THE CONTEXT
    // MUST BE CONFIGURED WITH AN ENTITY TYPE
    // CAN OPTIONALLY INCLUDE FILTERING AND SORTING

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "toolbar-cow"))
        navigationItem.rightBarButtonItem = editButtonItem
        
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
        
        // 3. USE THE FETCH REQUEST
        // ASK A CONTEXT TO EXECUTE THE REQUEST
        // ASK DATA CONTROLLER'S VIEW CONTEXT (PERSISTENT CONTROLLER'S VIEW CONTEXT)
        // .fetch() CAN THROW AN ERROR
        // SAVE THE RESULTS ONLY IF THE FETCH IS SUCCESSFUL
        // USE try? TO CONVERT THE ERROR INTO AN OPTIONAL
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            notebooks = result
            tableView.reloadData()
        }
        
        updateEditButtonState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: false)
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
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
        let notebook = Notebook(context: dataController.viewContext)
        notebook.name = name
        notebook.creationDate = Date()
        
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
     
        // INSERT NOTEBOOK AT POSITION 0, SINCE NOTEBOOKS ARE ORDERED BY CREATION DATE (LATEST ON TOP)
        // WE WILL ALSO INSERT THE NOTEBOOK INTO THE 0TH ROW OF THE TABLE
        
        notebooks.insert(notebook, at: 0)
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
        updateEditButtonState()
    }

    /// Deletes the notebook at the specified index path
    func deleteNotebook(at indexPath: IndexPath) {
        // 1. GET A REFERENCE TO THE NOTEBOOK TO DELETE
        // Using notebook(at:) "index path" helper function
        let notebookToDelete = notebook(at: indexPath)
        
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
        
        notebooks.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
        if numberOfNotebooks == 0 {
            setEditing(false, animated: true)
        }
        updateEditButtonState()
    }

    func updateEditButtonState() {
        navigationItem.rightBarButtonItem?.isEnabled = numberOfNotebooks > 0
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
        return numberOfNotebooks
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aNotebook = notebook(at: indexPath)
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

    // Helper

    var numberOfNotebooks: Int { return notebooks.count }

    func notebook(at indexPath: IndexPath) -> Notebook {
        return notebooks[indexPath.row]
    }

    // -------------------------------------------------------------------------
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If this is a NotesListViewController, we'll configure its `Notebook`
        if let vc = segue.destination as? NotesListViewController {
            if let indexPath = tableView.indexPathForSelectedRow {
                vc.notebook = notebook(at: indexPath)
            }
        }
    }
}

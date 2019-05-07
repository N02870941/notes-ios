//
//  ViewController.swift
//  notes
//
//  Created by jabari on 3/23/19.
//  Copyright © 2019 jabari. All rights reserved.
//

import UIKit

class NoteListViewController: UITableViewController {
    private let searchController: UISearchController
    private let addButtomItem:    UIBarButtonItem
    private let shareButtomItem:  UIBarButtonItem
    private let trashButton:      UIBarButtonItem
    private let selectAllButton:  UIBarButtonItem
    private let spacer:           UIBarButtonItem
    private let cellId:           String
    private let noteService:      NoteService
    
    private var selectedNotesMap: Dictionary<IndexPath, Note> {
        didSet {
            let notesAreSelected  = atLeastOneNoteSelected
            let selectedNoteCount = numberOfSelectedRows
            
            if selectedNoteCount == 0 {
                title = "Notes"
                selectAllButton.title = "Select all"
                shareButtomItem.isEnabled = false
            } else {
                let singularOrPlural = selectedNoteCount == 1 ? "note" : "notes"
                
                title = "\(selectedNoteCount) Selected"
                selectAllButton.title = "Unselect \(selectedNoteCount) \(singularOrPlural)"
                shareButtomItem.isEnabled = true
            }
            
            trashButton.isEnabled = notesAreSelected
        }
    }
    
    private var notes = [Note]() {
        didSet {
            let isEmpty = notes.isEmpty
            
            editButtonItem.isEnabled  = !isEmpty
        }
    }
    
    /// Disable the add button if we are searching
    private var isSearching = false {
        didSet {
            addButtomItem.isEnabled = !isSearching
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
        getNotes()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
        searchController.dismiss(animated: false, completion: nil)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) in
            self.searchController.searchBar.frame.size.width = self.view.frame.size.width
        }, completion: nil)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if isEditing {
            toolbarItems            = [selectAllButton, spacer, trashButton]
            editButtonItem.title    = "Done"
            addButtomItem.isEnabled = false
            enableShareButton()
            navigationController?.setToolbarHidden(false, animated: true)
        } else {
            title                 = "Notes"
            editButtonItem.title  = "Select"
            trashButton.isEnabled = false
            enableAddButton()
            navigationController?.setToolbarHidden(true, animated: true)
            
            if !isSearching {
                addButtomItem.isEnabled = true
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notes"
        
        /// Wrap the searchbar in a UIView to satisfy autolayout
        let headerView: UIView = {
            let width  = searchController.searchBar.frame.width
            let height = searchController.searchBar.frame.height
            let frame  = CGRect(x: 0, y: 0, width: width, height: height)
            let view   = UIView(frame: frame)
            view.addSubview(searchController.searchBar)
            return view
        }()
        
        /// Add a footer to satisfy UITableView height calculation
        let footerView = UIView(frame: .zero)
        
        /// Search bar
        searchController.searchBar.delegate                   = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation     = false
        searchController.searchBar.sizeToFit()
        
        /// Main UITableView
        tableView.keyboardDismissMode                  = .interactive
        tableView.allowsSelectionDuringEditing         = true
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.tableHeaderView                      = headerView
        tableView.tableFooterView                      = footerView
        
        /// Navigation itmes
        editButtonItem.isEnabled          = false
        editButtonItem.title              = "Select"
        navigationItem.leftBarButtonItem  = editButtonItem
        navigationItem.rightBarButtonItem = addButtomItem
        
        /// Other call to actions CTAs
        shareButtomItem.isEnabled = false
        trashButton.isEnabled     = false
        trashButton.tintColor     = .red
    }
    
    init() {
        searchController = UISearchController(searchResultsController: nil)
        addButtomItem    = UIBarButtonItem(barButtonSystemItem: .add,           target: nil, action: nil)
        shareButtomItem  = UIBarButtonItem(barButtonSystemItem: .action,        target: nil, action: nil)
        spacer           = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        trashButton      = UIBarButtonItem(barButtonSystemItem: .trash,         target: nil, action: nil)
        selectAllButton  = UIBarButtonItem(title: "Select all", style: .plain,  target: nil, action: nil)
        noteService      = NoteService.instance
        notes            = [Note]()
        cellId           = "cell"
        selectedNotesMap = [: ]
        
        super.init(style: .plain)
        
        spacer.target          = self
        addButtomItem.target   = self
        shareButtomItem.target = self
        trashButton.target     = self
        selectAllButton.target = self
        addButtomItem.action   = #selector(openNewNote)
        shareButtomItem.action = #selector(sendMultipleNotes)
        trashButton.action     = #selector(deleteSelectedNotes)
        selectAllButton.action = #selector(selectAllOrDeselectAllNotes)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension NoteListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        getNotes(then: resetSelectedNotes)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isSearching = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        isSearching = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text              = nil
        searchBar.showsCancelButton = false
        getNotes(then: resetSelectedNotes)
    }
}

extension NoteListViewController {
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        selectedNotesMap.removeValue(forKey: indexPath)
        
        if selectedNotesMap.isEmpty {
            trashButton.isEnabled     = false
            shareButtomItem.isEnabled = false
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismissKeyboard()
        let note = notes[indexPath.row]
        
        /// Mark note as selected
        if isEditing {
            trashButton.isEnabled       = true
            shareButtomItem.isEnabled   = true
            selectedNotesMap[indexPath] = note
            
        /// Otherwise, open it
        } else {
            openNote(note)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId) ?? UITableViewCell(style: .subtitle, reuseIdentifier: cellId)
        cell.initialize(from: notes[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        let note = notes.remove(at: indexPath.row)
        deleteNote(note)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        let numberOfSections = 1
        
        /// Hide background
        if !notes.isEmpty {
            tableView.separatorStyle  = .singleLine
            tableView.backgroundView  = nil
            tableView.isScrollEnabled = true
            
        // Show background
        } else {
            tableView.backgroundView  = NoNotesFoundView(frame: tableView.frame)
            tableView.separatorStyle  = .none
            tableView.isScrollEnabled = false
        }
        
        return numberOfSections
    }
}

private extension NoteListViewController {
    var numberOfSelectedRows: Int {
        return tableView.indexPathsForSelectedRows?.count ?? 0
    }
    
    var atLeastOneNoteSelected: Bool {
        return numberOfSelectedRows > 0
    }
    
    var selectedNotes: Set<Note> {
        return selectedNotesMap.valueSet
    }
    
    var selectedIndices: [IndexPath] {
        return selectedNotesMap.keyList
    }
    
    @objc func openNewNote() {
        let note = noteService.createNote(with: nil)
        openNote(note)
    }
    
    func openNote(_ note: Note) {
        let noteController = NoteController(note: note, noteService: noteService)
        navigationController?.pushViewController(noteController, animated: true)
    }
    
    func deleteNote(_ note: Note) {
        noteService.deleteNote(note: note)
    }
    
    @objc func sendMultipleNotes() {
        guard !selectedNotesMap.isEmpty else { return }
        noteService.sendNotes(selectedNotes, viewController: self)
    }
    
    @objc func deleteSelectedNotes() {
        guard !selectedNotesMap.isEmpty else { return }
        
        let message = "Delete \(selectedNotesMap.count) note(s)?"
        
        func onYes() {
            noteService.deleteNotes(selectedNotes) { [weak self] in
                guard let self = self else { return }
                self.setEditing(false, animated: true)
                self.selectedNotesMap.removeAll()
                self.getNotes()
            }
        }
        
        promptYesOrNo(withMessage: message,
                      onYes: onYes,
                      onNo: nil)
    }
    
    func getNotes(then completion: (() -> Void)? = nil) {
        notes = noteService.getAllNotes(containing: searchController.searchBar.text)
        
        tableView.reloadData()
        
        if let completion = completion {
            completion()
        }
    }
    
    func resetSelectedNotes() {
        guard isEditing else { return }
        
        selectedNotesMap.removeAll()
    }
    
    func enableAddButton() {
        navigationItem.rightBarButtonItem = addButtomItem
    }
    
    func enableShareButton() {
        navigationItem.rightBarButtonItem = shareButtomItem
    }
    
    func dismissKeyboard() {
        searchController.searchBar.resignFirstResponder()
    }
    
    @objc func selectAllOrDeselectAllNotes() {
        guard isEditing else { return }
        
        if atLeastOneNoteSelected {
            tableView.deselectAllRows()
        } else {
            tableView.selectAllRows()
        }
    }
}

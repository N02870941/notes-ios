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
    private let spacer:           UIBarButtonItem
    private let cellId:           String
    private let noteService:      NoteService
    
    /// Disabled the trash can if our selection count reaches 0
    private var selectedNotesMap: Dictionary<IndexPath, Note> {
        didSet {
            trashButton.isEnabled = !selectedNotesMap.isEmpty
        }
    }
    
    /// Disabled edit button if there are 0 notes to edit
    private var notes = [Note]() {
        didSet {
            editButtonItem.isEnabled = !notes.isEmpty
        }
    }
    
    /// Return only the Note objects that are selected
    private var selectedNotes: Set<Note> {
        return selectedNotesMap.valueSet
    }
    
    /// Return only the indicies of the selected cells
    private var selectedIndices: [IndexPath] {
        return selectedNotesMap.keyList
    }
    
    /// Disabled the add button if we are searching
    private var isSearching = false {
        didSet {
            addButtomItem.isEnabled = !isSearching
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
        tableView.allowsSelectionDuringEditing         = true
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.tableHeaderView                      = headerView
        tableView.tableFooterView                      = footerView
        
        /// Navigation itmes
        editButtonItem.isEnabled          = false
        editButtonItem.title              = "Select"
        navigationItem.leftBarButtonItem  = editButtonItem
        navigationItem.rightBarButtonItem = addButtomItem
        navigationController?.setToolbarHidden(true, animated: true)
        
        /// Other call to actions CTAs
        shareButtomItem.isEnabled = false
        trashButton.isEnabled     = false
        trashButton.tintColor     = .red
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getNotes()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchController.dismiss(animated: false, completion: nil)
    }
    
    init() {
        /// Initialize class properties
        searchController = UISearchController(searchResultsController: nil)
        addButtomItem    = UIBarButtonItem(barButtonSystemItem: .add,           target: nil, action: nil)
        shareButtomItem  = UIBarButtonItem(barButtonSystemItem: .action,        target: nil, action: nil)
        spacer           = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        trashButton      = UIBarButtonItem(barButtonSystemItem: .trash,         target: nil, action: nil)
        noteService      = NoteService.instance
        notes            = [Note]()
        cellId           = "cell"
        selectedNotesMap = [: ]
        
        super.init(style: .plain)
        
        /// Set selectors on CTAs
        spacer.target          = self
        addButtomItem.target   = self
        shareButtomItem.target = self
        trashButton.target     = self
        addButtomItem.action   = #selector(openNewNote)
        shareButtomItem.action = #selector(sendMultipleNotes)
        trashButton.action     = #selector(deleteSelectedNotes)
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
    private func enableAddButton() {
        navigationItem.rightBarButtonItem = addButtomItem
    }
    
    private func enableShareButton() {
        navigationItem.rightBarButtonItem = shareButtomItem
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if isEditing {
            toolbarItems            = [spacer, trashButton]
            editButtonItem.title    = "Done"
            addButtomItem.isEnabled = false
            enableShareButton()
            navigationController?.setToolbarHidden(false, animated: true)
        } else {
            editButtonItem.title  = "Select"
            trashButton.isEnabled = false
            enableAddButton()
            navigationController?.setToolbarHidden(true, animated: true)
            
            if !isSearching {
                addButtomItem.isEnabled = true
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        selectedNotesMap.removeValue(forKey: indexPath)
        
        if selectedNotesMap.isEmpty {
            trashButton.isEnabled     = false
            shareButtomItem.isEnabled = false
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
    
    // TODO: create a custom UITableViewCell and abstract initialization logic away
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let note = notes[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId) ?? UITableViewCell(style: .subtitle, reuseIdentifier: cellId)
        
        guard let textLabel = cell.textLabel else { return cell }
        textLabel.font = textLabel.font.bolded
        textLabel.text = note.title
        
        var detail = ""
        
        if let date = note.lastEditedDate?.formatted {
            detail += "\(date)\n"
        }
        
        detail += note.body?.firstLine.truncated(after: 30) ?? ""
        
        cell.detailTextLabel?.text          = detail
        cell.detailTextLabel?.textColor     = .gray
        cell.detailTextLabel?.numberOfLines = 0
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        
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

extension NoteListViewController {
    @objc private func openNewNote() {
        let message     = "Give your note a name"
        let placeholder = "Untitled"
        
        func onConfirm(title: String?) {
            let note = noteService.createNote(with: title)
            openNote(note)
        }
        
        promptForText(withMessage: message,
                      placeholder: placeholder,
                      onConfirm: onConfirm,
                      onCancel: nil)
    }
    
    private func openNote(_ note: Note) {
        let noteController = NoteController(note: note, noteService: noteService)
        navigationController?.pushViewController(noteController, animated: true)
    }
    
    private func deleteNote(_ note: Note) {
        noteService.deleteNote(note: note)
    }
    
    @objc private func sendMultipleNotes() {
        guard !selectedNotesMap.isEmpty else { return }
        noteService.sendNotes(selectedNotes, viewController: self)
    }
    
    @objc private func deleteSelectedNotes() {
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
    
    private func getNotes(then completion: (() -> Void)? = nil) {
        notes = noteService.getAllNotes(containing: searchController.searchBar.text)
        
        tableView.reloadData()
        
        if let completion = completion {
            completion()
        }
    }
    
    private func resetSelectedNotes() {
        guard isEditing else { return }
        
        selectedNotesMap.removeAll()
    }
}

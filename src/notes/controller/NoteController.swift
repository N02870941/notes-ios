//
//  NoteController.swift
//  notes
//
//  Created by jabari on 3/23/19.
//  Copyright © 2019 jabari. All rights reserved.
//

import UIKit

class NoteController: UIViewController {
    let textView = UITextView()
    private(set) var note: Note
    
    init(note: Note?) {
        self.note = note ?? Note(title: nil, body: nil)
        
        super.init(nibName:nil, bundle:nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        textView.frame.size.width = view.bounds.width
        textView.frame.size.height = view.bounds.height
    }
    
    override func viewDidLoad() {
        title = note.title ?? "Untitled note*"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(close))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(send))
                
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = note.body
        
        view.addSubview(textView)
    }
}

extension NoteController {
    @objc func send() {
        let alert = UIAlertController(title: "Coming soon", message: "Feature not yet implemented.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    @objc func close() {
        save { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }
    
    func save(completion: (() -> Void)? = nil) {
        NoteService.saveNote(note: note, completion: completion)
    }
}

//
//  NoteTableViewCell.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 29.10.2020.
//

import UIKit

class NoteTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var contentLabel: UILabel!
    @IBOutlet var reminderButton: UIButton!
    @IBOutlet var reminderDateLabel: UILabel!
    @IBOutlet var backedUpButton: UIButton!
}

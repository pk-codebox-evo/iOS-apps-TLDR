//
//  ViewController.swift
//  TLDR
//
//  Created by Suraj Pathak on 8/1/16.
//  Copyright © 2016 Suraj Pathak. All rights reserved.
//

import UIKit

let cellIdentifier = "cellIdentifier"

class ViewController: UIViewController {

    @IBOutlet weak var resultTextView: UITextView!
    @IBOutlet weak var commandTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    var suggestions: [Command] = [] {
        didSet {
            updateTableView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
        NetworkManager.checkAutoUpdate()
    }

    func updateUI() {
        tableView.dataSource = self
        tableView.delegate = self
        commandTextField.delegate = self
        resultTextView.delegate = self
        updateTableView()
        // Customize text field
        commandTextField.attributedPlaceholder = NSAttributedString(string: "_", attributes:
            [NSForegroundColorAttributeName:UIColor.lightTextColor()])
        commandTextField.clearButtonMode = .Always
        commandTextField.clearsOnBeginEditing = true
        // Customize text view
        resultTextView.backgroundColor = UIColor.clearColor()
        resultTextView.textColor = UIColor.whiteColor()
        resultTextView.font = UIFont(name: "Courier", size: 20)
        resultTextView.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: -10)
        resultTextView.selectable = true
        resultTextView.editable = false
        resultTextView.dataDetectorTypes = .Link
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        commandTextField.becomeFirstResponder()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateSuggestion", name:
            UITextFieldTextDidChangeNotification, object: commandTextField)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UITextFieldTextDidChangeNotification, object: commandTextField)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func updateSuggestion() {
        suggestions = StoreManager.getMatchingCommands(commandTextField.text!)
    }

    func lookUpWord(word: String, type: String) {
        let currentAttrText = NSMutableAttributedString(attributedString:
            CommandHelper.attributedTextForTLDRCommand(Command(name: word, type: type)))
        appendAttributeText(currentAttrText)
    }

    func appendAttributeText(currentAttrText: NSMutableAttributedString) {
        currentAttrText.appendAttributedString(NSAttributedString(string: "\n\n"))
        currentAttrText.appendAttributedString(resultTextView.attributedText)
        resultTextView.attributedText = currentAttrText
        resultTextView.scrollRectToVisible(CGRect(origin: CGPointZero, size: resultTextView.frame.size), animated: true)
        commandTextField.text = ""
        commandTextField.resignFirstResponder()
        suggestions.removeAll()
    }

    func updateTableView() {
        tableView.reloadData()
        let cellHeight = CGFloat(32.0)
        let maxCells = CGFloat(6.0)
        let cellsCount = min(maxCells, CGFloat(suggestions.count))
        tableViewHeightConstraint.constant = cellsCount * cellHeight
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if suggestions.count > 0 {
            lookUpWord(self.suggestions[0].name, type: self.suggestions[0].type)
        } else {
            if let commandName  = textField.text {
                lookUpWord(commandName, type: "common")
            }
        }
        suggestions.removeAll()
        return true
    }

    func textFieldShouldClear(textField: UITextField) -> Bool {
        suggestions.removeAll()
        return true
    }
}

extension ViewController: UITextViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        commandTextField.resignFirstResponder()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestions.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        if let cachedCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) {
            cell = cachedCell
        } else {
            cell = UITableViewCell(style: .Value1, reuseIdentifier: cellIdentifier)
            cell?.backgroundColor = UIColor.clearColor()
            cell?.textLabel?.textColor = UIColor.lightTextColor()
        }
        cell!.textLabel!.text = suggestions[indexPath.row].name
        cell!.detailTextLabel!.text = suggestions[indexPath.row].type
        return cell!
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        commandTextField.text = suggestions[indexPath.row].name
        lookUpWord(suggestions[indexPath.row].name, type: suggestions[indexPath.row].type)
    }
}

extension ViewController {

    @IBAction func clearConsole(sender: AnyObject) {
        resultTextView.attributedText = NSMutableAttributedString(string: "")
    }

    @IBAction func appendAboutUs(sender: AnyObject) {
        let aboutUs = MarkDownParser.attributedStringOfMarkdownString(aboutUsMarkdown)
        appendAttributeText(NSMutableAttributedString(attributedString: aboutUs))
    }
}

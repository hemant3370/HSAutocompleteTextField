//
//  HSAutocompleteTextField.swift
//  HSAutocompleteTextField
//
//  Created by Hemant Singh on 13/11/20.
//  Copyright © 2020 Hemant Singh. All rights reserved.
//

import UIKit

protocol Listable {
    var identifier: String { get }
    func displayText() -> String
}

class HSAutocompleteTextField<T: Listable & Equatable>: UITextField, UITableViewDelegate, UITableViewDataSource {
    
    var dataList : Array<T> = []
    var multiSelect: Bool = false
    
    private var resultsList : Array<T> = []
    private var tableView: UITableView?
    private var keyBoardHeight: CGFloat = 0
    var selections: Array<T> = []
    // Connecting the new element to the parent view
    open override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        tableView?.removeFromSuperview()
        //        NotificationCenter.default.removeObserver(self)
    }
    
    override open func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        self.addTarget(self, action: #selector(HSAutocompleteTextField.textFieldDidChange), for: .editingChanged)
        self.addTarget(self, action: #selector(HSAutocompleteTextField.textFieldDidBeginEditing), for: .editingDidBegin)
        self.addTarget(self, action: #selector(HSAutocompleteTextField.textFieldDidEndEditing), for: .editingDidEnd)
        self.addTarget(self, action: #selector(HSAutocompleteTextField.textFieldDidEndEditingOnExit), for: .editingDidEndOnExit)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            keyBoardHeight = keyboardSize.height
        }
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        buildSearchTableView()
    }
    
    @objc open func textFieldDidChange(){
        filter()
        updateSearchTableView()
        tableView?.isHidden = false
    }
    
    @objc open func textFieldDidBeginEditing() {
        if !selections.isEmpty && multiSelect {
            text?.append(", ")
        }
    }
    
    @objc open func textFieldDidEndEditing() {
        tableView?.isHidden = true
        if multiSelect { self.text = selections.compactMap({ $0.displayText() }).joined(separator: ", ") }
    }
    
    @objc open func textFieldDidEndEditingOnExit() {
        
    }
    // MARK: Filtering methods
    
    fileprivate func filter() {
        let query = text?.components(separatedBy: ", ").last
        resultsList = dataList.filter({ $0.displayText().lowercased().starts(with: query?.lowercased() ?? " ") })
        tableView?.reloadData()
    }
    
    // MARK: TableViewDataSource methods
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsList.count
    }
    
    // MARK: TableViewDelegate methods
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "AutocompleteTextFieldCell")
        cell.textLabel?.text = resultsList[indexPath.row].displayText()
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.accessoryType = selections.contains(resultsList[indexPath.row]) ? .checkmark : .none
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if multiSelect {
            let selection = resultsList[indexPath.row]
            if selections.contains(selection) {
                selections.removeAll(where: { $0 == selection })
                self.text = selections.compactMap({ $0.displayText() }).joined(separator: ", ")
            } else {
                selections.append(selection)
                self.text = selections.compactMap({ $0.displayText() }).joined(separator: ", ").appending(", ")
            }
        } else {
            self.text = resultsList[indexPath.row].displayText()
            selections = [resultsList[indexPath.row]]
            tableView.isHidden = true
            self.endEditing(true)
        }
    }
    
}

extension HSAutocompleteTextField {
    // MARK: TableView creation and updating
    
    // Create SearchTableview
    func buildSearchTableView() {
        if let tableView = tableView {
            tableView.delegate = self
            tableView.dataSource = self
            self.window?.addSubview(tableView)
        } else {
            tableView = UITableView(frame: CGRect.zero)
        }
        tableView?.allowsMultipleSelection = multiSelect
        updateSearchTableView()
    }
    
    // Updating SearchtableView
    func updateSearchTableView() {
        if let tableView = tableView {
            superview?.bringSubview(toFront: tableView)
            var tableHeight: CGFloat = 0
            let originInWindow = getCoordinate(self)
            let availableHeight = (window?.bounds.height ?? 0) - keyBoardHeight
            var yOrigin: CGFloat = 0
            if originInWindow.y > availableHeight / 2 {
                tableHeight = min(tableView.contentSize.height, originInWindow.y - 64)
                yOrigin = -min(tableView.contentSize.height, originInWindow.y - 64)
            } else {
                tableHeight = availableHeight - originInWindow.y
                yOrigin = 50
            }
            
            // Set tableView frame
            var tableViewFrame = CGRect(x: 0, y: yOrigin, width: frame.size.width - 4, height: tableHeight)
            tableViewFrame.origin = self.convert(tableViewFrame.origin, to: nil)
            tableViewFrame.origin.x += 2
            UIView.animate(withDuration: 0.2, animations: { [weak self] in
                self?.tableView?.frame = tableViewFrame
            })
            
            //Setting tableView style
            tableView.layer.masksToBounds = true
            tableView.separatorInset = UIEdgeInsets.zero
//            tableView.layer.cornerRadius = 5.0
            tableView.separatorColor = UIColor.clear
            tableView.backgroundColor = UIColor.clear
            if self.isFirstResponder {
                superview?.bringSubview(toFront: self)
            }
            tableView.reloadData()
        }
    }
    
    func getCoordinate(_ view: UIView) -> CGPoint {
        var x = view.frame.origin.x
        var y = view.frame.origin.y
        var oldView = view

        while let superView = oldView.superview {
            x += superView.frame.origin.x
            y += superView.frame.origin.y
            if superView.next is UIViewController {
                break //superView is the rootView of a UIViewController
            }
            oldView = superView
        }
        return CGPoint(x: x, y: y)
    }
}

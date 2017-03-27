//
//  ViewController.swift
//  LPUITools
//
//  Created by LP on 2017/3/18.
//  Copyright © 2017年 zou. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    //  property
    fileprivate var tableView: UITableView?
    fileprivate let titles = ["Video Player"]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.backgroundColor = UIColor.white
        
        //  view
        self.createTableView()
    }

    // MARK: - UI
    //  table
    func createTableView() {
        tableView = UITableView(frame: self.view.bounds, style: UITableViewStyle.plain)
        tableView?.backgroundColor = UIColor.clear
        tableView?.delegate = self
        tableView?.dataSource  = self
        tableView?.tableFooterView = UIView()
        tableView?.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        self.view.addSubview(tableView!)
    }

    // MARK: - UITableViewDelegate
    internal func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //  cell
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
            case 0:
                let video = TestVideoPlayerViewController()
                video.title = self.titles[indexPath.row]
                self.navigationController?.pushViewController(video, animated: true)
            break
            default:
            break
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //  data
        return 48
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if nil == cell {
            cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "cell")
        }
        
        cell?.textLabel?.text = self.titles[indexPath.row]
        
        return cell!
    }

}


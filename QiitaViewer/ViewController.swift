//
//  ViewController.swift
//  QiitaViewer
//
//  Created by Daiki Kojima on 2019/02/21.
//  Copyright © 2019 Daiki Kojima. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var qiitaTable: UITableView!
    var qiitaContents: [Qiita] = []
    var count = 2
    var isLoading = false
    let jsonDateFormatter = DateFormatter()
    let qiitaDate = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        qiitaTable.dataSource = self
        qiitaTable.delegate = self
        qiitaTable.register(UINib(nibName: "QiitaCell", bundle: nil), forCellReuseIdentifier: "QiitaCell")
        qiitaTable.estimatedRowHeight = 200
        qiitaTable.rowHeight = UITableView.automaticDimension
        jsonDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        qiitaDate.dateFormat = "yyyy年MM月dd日"
        Alamofire.request("https://qiita.com/api/v2/items?page=1&per_page=20").responseJSON{ response in
            if let data = response.result.value {
                let jsonArray = JSON(data)
                if jsonArray["type"] == "rate_limit_exceeded" {
                    return
                }
                jsonArray.forEach { (_, json) in
                    let jsonDate = self.jsonDateFormatter.date(from: json["created_at"].string!)
                    let qiitaContent = Qiita(
                        title: json["title"].string!,
                        author: json["user"]["id"].string!,
                        date: self.qiitaDate.string(from: jsonDate!),
                        url: URL(string: json["url"].string!)!
                    )
                    self.qiitaContents.append(qiitaContent)
                }
                self.qiitaTable.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return qiitaContents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "QiitaCell") as! QiitaCell
        cell.titleLabel.text = qiitaContents[indexPath.row].title
        cell.authorLabel.text = qiitaContents[indexPath.row].author
        cell.dateLabel.text = qiitaContents[indexPath.row].date
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let url = qiitaContents[indexPath.row].url
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.qiitaTable.contentOffset.y + self.qiitaTable.frame.size.height > self.qiitaTable.contentSize.height &&
                self.qiitaTable.isDragging && !isLoading {
            self.isLoading = true
            print("Count is \(count)")
            Alamofire.request("https://qiita.com/api/v2/items?page=\(count)&per_page=20").responseJSON{ response in
                if let data = response.result.value {
                    let jsonArray = JSON(data)
                    if jsonArray["type"] == "rate_limit_exceeded" {
                        return
                    }
                    jsonArray.forEach { (_, json) in
                        let jsonDate = self.jsonDateFormatter.date(from: json["created_at"].string!)
                        let qiitaContent = Qiita(
                            title: json["title"].string!,
                            author: json["user"]["id"].string!,
                            date: self.qiitaDate.string(from: jsonDate!),
                            url: URL(string: json["url"].string!)!
                        )
                        self.qiitaContents.append(qiitaContent)
                    }
                    self.qiitaTable.reloadData()
                    self.count += 1
                    self.isLoading = false
                }
            }
        }
    }
}

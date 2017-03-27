//
//  TestVideoPlayerViewController.swift
//  LPUITools
//
//  Created by LP on 2017/3/18.
//  Copyright © 2017年 zou. All rights reserved.
//

import UIKit

class TestVideoPlayerViewController: UIViewController {
    
    //  test
    fileprivate let player: LPPlayer = LPPlayer(frame: CGRect(x: 0, y: 80, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.width * 0.76))
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.white
        
        self.view.addSubview(self.player)
        
        self.player.play(url: URL(string: "http://mvideo.spriteapp.cn/video/2017/0326/58d6aa21f16a2.mp4")!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

//
//  LPPlayer.swift
//  LPUITools
//
//  Created by LP on 2017/3/18.
//  Copyright © 2017年 zou. All rights reserved.
//

import UIKit
import AVFoundation

//  播放器状态定义
enum LPPlayerStatus {
    case loading        // 加载等待中
    case playing        // 正在播放
    case pause          // 暂停
    case playedComplete // 播放结束
    case stop           // 终止播放
    case error          // 出现错误
}

protocol LPPlayerDelegate : class {
    func lpPlayer(player: LPPlayer ,changeStatus status: LPPlayerStatus)
    func lpPlayer(player: LPPlayer ,loadedProgress progress: CGFloat)
    func lpPlayer(player: LPPlayer ,playProgress progress: CGFloat)
}

class LPPlayer: UIView {
    
    /*
    	@property		delegate
    	@abstract		player delegate
     */
    open weak var delegate: LPPlayerDelegate?
    
    /*
    	@property		loopPlay
    	@abstract		循环播放播放视频
     */
    open var loopPlay: Bool = false
    
    /*
    	@property		player
    	@abstract		media file player layer
     */
    fileprivate var playerLayer: AVPlayerLayer = AVPlayerLayer()
    
    /*
    	@property		immediatelyPlay
    	@abstract		immediately Play the file
     */
    fileprivate var immediatelyPlay : Bool = true
    
    //  private property
    fileprivate var playClockTimeObserver : Any?

    
    //  MARK: - init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    //  MARK: - play
    func play(url: URL) {
        self.play(playerItem: AVPlayerItem(url: url))
    }
    
    func play(playerItem: AVPlayerItem) {
        if (self.playerLayer.player == nil)
        {
            self.playerLayer.player = AVPlayer(playerItem: playerItem)
            self.playerLayer.player?.allowsExternalPlayback = true;
            self.addPlayerObserver()
        }
        else
        {
            self.removePlayerObserver()
            self.playerLayer.player?.replaceCurrentItem(with: playerItem)
        }
        
        //  移除观察者
        self.addPlayerNotification()
        
        //  添加观察者
        self.addPlayerItemObserver()
        
        //  立即播放
        self.immediatelyPlay = true
        
        //  进度观察
        self.addPlayerTimeObservers()
    }
    
    func stop() {
        self.playerLayer.player?.pause()
        self.removePlayerNotification()
        self.removePlayerObserver()
        self.removePlayerItemObserver()
        self.removePlayerTimeObservers()
        
        //  取消暂停
        self.immediatelyPlay = true
        
        //  代理
        self.delegate?.lpPlayer(player: self, changeStatus: LPPlayerStatus.stop)
    }
    
    func pause() {
        self.playerLayer.player?.pause()
        
        //  取消暂停
        self.immediatelyPlay = false
    }
    
    func resume() {
        self.playerLayer.player?.play()
        
        //  取消暂停
        self.immediatelyPlay = true
    }
    
    func duration() -> CGFloat {
        if self.playerLayer.player?.currentItem != nil {
            return CGFloat(CMTimeGetSeconds((self.playerLayer.player?.currentItem?.duration)!))
        }
        return 0;
    }
    
    func isPause() -> Bool {
        return 0.0 == self.playerLayer.player?.rate
    }
    
    func seekToTime(time: TimeInterval) {
        if time < 0 || time > Double(self.duration()) {
            return
        }
        
        self.pause()

        self.immediatelyPlay = true
        
        let toTime = CMTimeMake(Int64(time * 30), 30)
        
        weak var weakSelf = self
        self.playerLayer.player?.seek(to: toTime, toleranceBefore: CMTimeMake(1, 30), toleranceAfter: CMTimeMake(1, 30), completionHandler: { (finished) in
            if (weakSelf != nil) && finished && (weakSelf?.immediatelyPlay)! {
                weakSelf?.resume()
            }
        })
    }

    
    //  MARK: - commonInit
    fileprivate func commonInit() {
        self.backgroundColor = UIColor.black
        self.layer.addSublayer(self.playerLayer)
    }
    
    //  MARK: - layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //  layout son views
        self.playerLayer.frame = self.bounds;
    }
    
    //  MARK: - player config
    fileprivate func addPlayerNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.onAVPlayerItemDidPlayToEndTime(notification:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: self.playerLayer.player?.currentItem)
    }
    
    fileprivate func removePlayerNotification() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    fileprivate func addPlayerObserver() {
        self.playerLayer.player?.addObserver(self, forKeyPath: "readyForDisplay", options: NSKeyValueObservingOptions.new, context: nil)
        self.playerLayer.player?.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    fileprivate func removePlayerObserver() {
        self.playerLayer.player?.removeObserver(self, forKeyPath: "readyForDisplay")
        self.playerLayer.player?.removeObserver(self, forKeyPath: "rate")
    }
    
    fileprivate func addPlayerItemObserver() {
        self.playerLayer.player?.currentItem?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        self.playerLayer.player?.currentItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: NSKeyValueObservingOptions.new, context: nil)
        self.playerLayer.player?.currentItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: NSKeyValueObservingOptions.new, context: nil)
        self.playerLayer.player?.currentItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    fileprivate func removePlayerItemObserver() {
        self.playerLayer.player?.currentItem?.removeObserver(self, forKeyPath: "status")
        self.playerLayer.player?.currentItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        self.playerLayer.player?.currentItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        self.playerLayer.player?.currentItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
    }
    
    //  MARK: - kvo
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "status"
        {
            let status = self.playerLayer.player?.currentItem?.status
            if status == AVPlayerItemStatus.readyToPlay {
                if self.immediatelyPlay
                {
                    self.playerLayer.player?.play()
                }
                else
                {
                    self.playerLayer.player?.pause()
                }
            }
            else if status == AVPlayerItemStatus.unknown
            {
                self.delegate?.lpPlayer(player: self, changeStatus: LPPlayerStatus.error)

            }
            else if status == AVPlayerItemStatus.failed
            {
                self.delegate?.lpPlayer(player: self, changeStatus: LPPlayerStatus.error)
            }
        }
        else if keyPath == "playbackBufferEmpty"
        {
            self.delegate?.lpPlayer(player: self, changeStatus: LPPlayerStatus.loading)
        }
        else if keyPath == "playbackLikelyToKeepUp"
        {
            if self.immediatelyPlay && self.isPause()
            {
                self.resume()
            }
        }
        else if keyPath == "loadedTimeRanges"
        {
            //  代理
            self.delegate?.lpPlayer(player: self, loadedProgress: self.preloadedProgress())
        }
        else if keyPath == "readyForDisplay"
        {
            if self.immediatelyPlay && self.isPause()
            {
                self.resume()
            }
        }
        else if keyPath == "rate"
        {
            let currentStatus = self.isPause() ? LPPlayerStatus.pause : LPPlayerStatus.playing
            self.delegate?.lpPlayer(player: self, changeStatus: currentStatus)
        }
    }
    
    //  MARK: - Notifications
    @objc fileprivate func onAVPlayerItemDidPlayToEndTime(notification: NSNotification) {
        let playerItem = notification.object as? AVPlayerItem
        
        if playerItem == self.playerLayer.player?.currentItem {
            
            self.delegate?.lpPlayer(player: self, changeStatus: LPPlayerStatus.playedComplete)
            
            //  循环播放
            if self.loopPlay {
                self.playerLayer.player?.seek(to: CMTimeMake(0, 1))
                self.playerLayer.player?.play()
            }
        }
    }
    
    //  MARK: - progress
    fileprivate func durationTime() -> CMTime {
        if self.playerLayer.player?.status == AVPlayerStatus.readyToPlay {
            return (self.playerLayer.player?.currentItem!.duration)!
        }
        return kCMTimeInvalid
    }
    
    fileprivate func currentPlayTime() -> CMTime {
        if self.playerLayer.player?.status == AVPlayerStatus.readyToPlay {
            return (self.playerLayer.player?.currentItem!.currentTime())!
        }
        return kCMTimeInvalid
    }
    
    fileprivate func availableDuration() -> CGFloat {
        let loadedTimeRanges = self.playerLayer.player?.currentItem?.loadedTimeRanges
        
        //  Check to see if the timerange is not an empty array, fix for when media goes on airplay
        //  and media doesn't include any time ranges
        if (loadedTimeRanges?.count)! > 0 {
            let timeRange = loadedTimeRanges?[0].timeRangeValue
            let startSeconds = CGFloat(CMTimeGetSeconds((timeRange?.start)!))
            let durationSeconds = CGFloat(CMTimeGetSeconds((timeRange?.duration)!))
            return (startSeconds + durationSeconds)
        }
        
        return 0.0;
    }
    
    //  预加载进度
    func preloadedProgress() -> CGFloat {
        let durationTime = CGFloat(CMTimeGetSeconds((self.playerLayer.player?.currentItem?.duration)!))
        let bufferTime = self.availableDuration()

        var progress: CGFloat = 0.0;
        
        //  0
        if (durationTime > 0) {
            progress = bufferTime / durationTime
        }

        //  :进度有可能加载不到100%。下列情况按照加载完成处理
        if (((durationTime - bufferTime) < 2 && durationTime > 15)
            || ((durationTime - bufferTime) < 4 &&  durationTime > 120)
            || progress > 0.993) {
            progress = 1.0;
        }
        
        return progress;
    }
    
    fileprivate func addPlayerTimeObservers() {
        //  remove
        self.removePlayerTimeObservers()

        //  add new
        weak var weakSelf = self
        self.playerLayer.player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.01, Int32(NSEC_PER_SEC)), queue: nil, using: { (CMTime) in
            weakSelf?.syncPlayClock()
        })
    }
    
    fileprivate func removePlayerTimeObservers() {
        if self.playClockTimeObserver != nil {
            self.playerLayer.player?.removeTimeObserver(self.playClockTimeObserver!)
            self.playClockTimeObserver = nil
        }
    }
    
    fileprivate func syncPlayClock() {
        let playerDuration = self.durationTime()
        if CMTIME_IS_INVALID(playerDuration) {
            return;
        }
    
        let currentTime = self.currentPlayTime()
        if CMTIME_IS_INDEFINITE(currentTime) {
            return;
        }
    
        var progress: CGFloat = 0
        
        //  进度
        let duration = CGFloat(CMTimeGetSeconds(playerDuration))
        let time = CGFloat(CMTimeGetSeconds(currentTime))
        if duration > 0 && time > 0 && duration >= time {
            progress = time / duration
        }
        
        //  代理
        self.delegate?.lpPlayer(player: self, playProgress: progress)
    }

    //  MARK: - deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
        self.stop()
    }
}


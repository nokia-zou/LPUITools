//
//  LPVideoPlayer.swift
//  LPUITools
//
//  Created by LP on 2017/3/18.
//  Copyright © 2017年 zou. All rights reserved.
//

import UIKit
import AVFoundation

enum LPPlayerStatus {
    case loading        // 加载等待中
    case playing        // 正在播放
    case pause          // 暂停
    case playedComplete // 播放结束
    case error          // 出现错误
}

enum LPPlayerEvent {
    case startLoad      // 开始加载
    case resumePlay     // 回复播放
    case stop           // 停止
}


protocol LPPlayerDelegate : class {
    func lpPlayer(player: LPPlayer ,changeStatus status: LPPlayerStatus)
    
    func lpPlayer(player: LPPlayer ,actionEvent event: LPPlayerStatus)

    func lpPlayer(player: LPPlayer ,loadedProgress progress: CGFloat)
    func lpPlayer(player: LPPlayer ,playProgress progress: CGFloat)
}

class LPPlayer: UIView {
    
    /*
    	@property		delegate
    	@abstract		media file player layer
     */
    open weak var delegate: LPPlayerDelegate?
    
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
    
    fileprivate func commonInit() {
        self.backgroundColor = UIColor.black
        self.layer.addSublayer(self.playerLayer)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        self.stop()
    }
    
    //  MARK: - layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //  layout son views
        self.playerLayer.frame = self.bounds;
    }
    
    //  MARK: - play
    func play(url: URL) {
        self.play(playerItem: AVPlayerItem(url: url))
    }
    
    func play(playerItem: AVPlayerItem) {
        if (self.playerLayer.player == nil) {
            self.playerLayer.player = AVPlayer(playerItem: playerItem)
            self.playerLayer.player?.allowsExternalPlayback = true;
            self.addPlayerObserver()
        }
        else {
            self.removePlayerObserver()
            self.playerLayer.player?.replaceCurrentItem(with: playerItem)
        }
        
        //  停止播放移除
        self.addVideoPlayerNotification()
        
        //  添加观察者
        self.addPlayerItemObserver()
    }
    
    func stop() {
//        _isSeekingProgress = NO;
        
        self.playerLayer.player?.pause()
        self.removeVideoPlayerNotification()
        self.removePlayerObserver()
        self.removePlayerItemObserver()
        self.removePlayerTimeObservers()
        
        //  取消暂停
        self.immediatelyPlay = false
        
        //  代理
//        [self delegateEvent:ELVideoPlayerEventStop];
    
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
    
    
    //  MARK: - player config
    
    fileprivate func addVideoPlayerNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.onAVPlayerItemDidPlayToEndTime(notification:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: self.playerLayer.player?.currentItem)
    }
    
    fileprivate func removeVideoPlayerNotification() {
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
        
        if keyPath == "status" {
            let status = self.playerLayer.player?.currentItem?.status
            if status == AVPlayerItemStatus.readyToPlay {
                if self.immediatelyPlay {
                    self.playerLayer.player?.play()
                }
                else {
                    self.playerLayer.player?.pause()
                }
            }
            else if status == AVPlayerItemStatus.unknown {
                
            }
            else if status == AVPlayerItemStatus.failed {
                
            }
        }
        else if keyPath == "playbackBufferEmpty" {
            
        }
        else if keyPath == "playbackLikelyToKeepUp" {
            
        }
        else if keyPath == "loadedTimeRanges" {
            
        }
        else if keyPath == "readyForDisplay" {
            
        }
        else if keyPath == "rate" {
            
        }
    }
    
    //  MARK: - Notifications
    @objc fileprivate func onAVPlayerItemDidPlayToEndTime(notification: NSNotification) {
        
    }
    
    //  MARK: - progress
    fileprivate func playerItemDuration() -> CMTime {
        if self.playerLayer.player?.status == AVPlayerStatus.readyToPlay {
            return (self.playerLayer.player?.currentItem!.duration)!
        }
        return kCMTimeInvalid
    }
    
    fileprivate func updatePlaybackProgress() {
        let playerDuration = self.playerItemDuration()
        if CMTIME_IS_INVALID(playerDuration) { return }
        
        let duration = CMTimeGetSeconds(playerDuration);
        if CMTIME_IS_INDEFINITE(playerDuration) || duration <= 0 {
//            [self syncPlayClock];
            return;
        }
        
        //  remove
        self.removePlayerTimeObservers()

        //  add new
        self.playerLayer.player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.01, Int32(NSEC_PER_SEC)), queue: nil, using: { (CMTime) in
            //            [weakSelf syncPlayClock];

        })
    }
    
    fileprivate func removePlayerTimeObservers() {
        if self.playClockTimeObserver != nil {
            self.playerLayer.player?.removeTimeObserver(self.playClockTimeObserver!)
            self.playClockTimeObserver = nil
        }
    }
    
    fileprivate func syncPlayClock() {
        let playerDuration = self.playerItemDuration()
        if (CMTIME_IS_INVALID(playerDuration)) {
            return;
        }
    
        if (CMTIME_IS_INDEFINITE(playerDuration)) {
            return;
        }
    
        let duration = CMTimeGetSeconds(playerDuration);
        if (duration > 0) {
    
            //  视频播放进度
//            let currentTime = CMTimeGetSeconds(self.playerLayer.player!.currentTime())
    
//            if ([_delegate respondsToSelector:@selector(listVideoPlayer:playProgress:)]) {
//                    [_delegate listVideoPlayer:self playProgress:currentTime / duration];
//            }
        }
    }
    
    fileprivate func availableDuration() -> CGFloat {
        let loadedTimeRanges = self.playerLayer.player?.currentItem?.loadedTimeRanges
        
        // Check to see if the timerange is not an empty array, fix for when video goes on airplay
        // and video doesn't include any time ranges
        if ((loadedTimeRanges?.count)! > 0) {
            let timeRange = loadedTimeRanges?[0].timeRangeValue
            let startSeconds = CGFloat(CMTimeGetSeconds((timeRange?.start)!))
            let durationSeconds = CGFloat(CMTimeGetSeconds((timeRange?.duration)!))
            return (startSeconds + durationSeconds)
        }
        
        return 0.0;
    }

}


//
//  AVPlayerTestController.swift
//  PlayVideo
//
//  Created by 王锦涛 on 2018/7/18.
//  Copyright © 2018年 JTWang. All rights reserved.
//

import UIKit
import AVFoundation

class AVPlayerTestController: UIViewController {
    
    lazy var localVideoUrl : URL? = {
        if let urlStr = Bundle.main.path(forResource: "Cupid_高清", ofType: "mp4") {
            return URL.init(fileURLWithPath: urlStr)
        }
        return nil
    }()
        

    let urlStr = "http://yun.it7090.com/video/XHLaunchAd/video03.mp4"
    
    var url : URL? {
        return URL.init(string: urlStr)
    }
    
    var player : AVPlayer?
    var asset  : AVURLAsset?
    var playerItem : AVPlayerItem?
    var playerLayer : AVPlayerLayer?
    
    var observer : Any?
    
    /*
        1,画面的展示 （单纯的AVPlayer是没有展示层的，需要自己实现）
        2,监听播放进度
        3,KVO添加对AVPlayerItem监听的时候，要保证不要重复添加监听， 会崩溃
        4，CMTime 很有意思的一个结构体  有两个关键值  value  和  timescale, seconds =  value /  timescale,  其中测试发现 timescale只能是整数
         5, loadValuesAsynchronouslyForKeys ？
        6, rate ？ AVPlayer的属性
            0表示暂停，  1.0表示正在以原始速率播放当前item，如果播放器的AVPlayerItem属性canPlaySlowForward或canPlayFastForward返回true，则可以使用0.0和1.0之外的费率。如果AVPlayerItem返回的是canPlayReverse, canPlaySlowReverse和canPlayFastReverse属性，则支持负速率值范围。
     */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let url = localVideoUrl else {
            return
        }
        
        
        
        
        let item = AVPlayerItem.init(url: url)
        let player = AVPlayer.init(playerItem: item)
        playerItem = item
        self.player = player
        playerLayer = AVPlayerLayer.init(player: player)
        playerLayer?.videoGravity = .resizeAspect
        playerLayer?.frame = self.view.bounds
        self.view.layer.addSublayer(playerLayer!)
        

        addItemObserver()
    }
    /*
        AVAsynchronousKeyValueLoading 协议规定了两个方法：
        1，获取状态的方法
        public func statusOfValue(forKey key: String, error outError: NSErrorPointer) -> AVKeyValueStatus
        根据key值返回状态，  状态是一个枚举 
        2，异步去下载值的方法
        public func loadValuesAsynchronously(forKeys keys: [String], completionHandler handler: (() -> Swift.Void)? = nil)
        告诉资源去下载指定数组中还没有下载完成的key。不管指定的key值多少， 方法中的handler将会在以下两种情况下回调： 1，当所有指定的key已经下载完成，或者IO错误， 格式错误的时候会同步回调handle。2，当所有的key下载完成，或者加载出错，或者取消，会异步的调用handle，  如果想在闭包中刷新UI，需要先回到主线程
     */
    
    /// AVURLAsset 
    func assetTest(){
        guard let url = url else {
            return
        }
        let assert = AVURLAsset.init(url: url)
        assert.loadValuesAsynchronously(forKeys: ["playable"]) {
            DispatchQueue.main.async {
                print("asdfasf")
            }
        }
//        let error  : NSError?
//        assert.statusOfValue(forKey: "playable", error: )
        self.asset = assert
    }

    // 设置 avPlayerItem 观察者，监听播放、缓冲进度
    fileprivate func addItemObserver() {
        guard let playerItem = self.playerItem else { return  }
        playerItem.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        playerItem.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil)
        playerItem.addObserver(self, forKeyPath: "playbackBufferEmpty", options: NSKeyValueObservingOptions.new, context: nil)
        playerItem.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    fileprivate func removeItemObserver() {
        playerItem?.removeObserver(self, forKeyPath: "status")
        playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        playerItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        playerItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
    }
    
    
    
    /// 对播放器 进度添加监听  提供了两个方法，  第一个一个是指定时间间隔，   第二个是指定时间点，使用时回调方式是闭包，  所以在闭包中要注意避免循环引用
    fileprivate func addPlayBackObserver(){
        if let player = self.player {
            player.addPeriodicTimeObserver(forInterval: CMTime.init(value: CMTimeValue(1.0), timescale: CMTimeScale(1.0)), queue: DispatchQueue.main) { [unowned self] (cmtime) in
                let second  = CMTimeGetSeconds(cmtime)
//                print("🐂\(second)")
                print("\(self.player?.rate)")
            }
            
            let asdf = NSValue.init(time: CMTime.init(value: CMTimeValue(10), timescale: CMTimeScale(1)))
            let asdasdff = NSValue.init(time: CMTime.init(value: CMTimeValue(20), timescale: CMTimeScale(1)))

            player.addBoundaryTimeObserver(forTimes: [asdf,asdasdff], queue: DispatchQueue.main) { [unowned self] in

                print("❤️\(self.playerItem?.currentTime())")
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let playerItem = object as? AVPlayerItem else { return }
        
        if keyPath == "status" {
            if playerItem.status == AVPlayerItemStatus.readyToPlay {
                print("readyToPlay")
//                let duration  = CMTimeGetSeconds(playerItem.duration)
//                self.dura = Float(duration)
//                durationTimeLabel.text = timeStr(seconds: Int(duration))
//                play()
//                isPlaying = true
                player?.play()
                addPlayBackObserver()
                
                
            }
        } else if keyPath == "loadedTimeRanges" {
            
            // 计算缓冲进度
            guard let item = self.playerItem else {
                return
            }
            let timeInterval = self.availableDuration()
            let duration = item.duration
            let totalDuration = CMTimeGetSeconds(duration)
            if totalDuration != 0 {
                debugPrint("loadedTimeRanges = \(timeInterval / totalDuration)")
            }
            
        } else if keyPath == "playbackBufferEmpty" {
            
            print("playbackBufferEmpty")
        } else if keyPath == "playbackLikelyToKeepUp" {
            
            // 当缓冲好的时候
            print("playbackLikelyToKeepUp")
        }
    }
    
    /// 计算缓冲进度
    ///
    /// - Returns: 缓冲进度
    fileprivate func availableDuration() -> TimeInterval {
        let loadedTimeRanges = self.player?.currentItem?.loadedTimeRanges
        let timeRanges = (loadedTimeRanges?.first)?.timeRangeValue
        let startSeconds = CMTimeGetSeconds((timeRanges?.start)!)
        let durationSeconds = CMTimeGetSeconds((timeRanges?.duration)!)
        let result = startSeconds + durationSeconds
        return result
    }
    
    func deallocPlayer(){
        removeItemObserver()
        self.asset = nil
        self.playerItem = nil
        self.player = nil
    }
    
    deinit {
        deallocPlayer()
    }

}

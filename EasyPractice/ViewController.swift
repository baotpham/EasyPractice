//
//  ViewController.swift
//  EasyPractice
//
//  Created by Bao Pham on 7/9/15.
//  Copyright (c) 2015 BaoPham. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation

class ViewController: UIViewController, MPMediaPickerControllerDelegate{
    
    
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var songName: UILabel!
    @IBOutlet weak var artist: UILabel!
    @IBOutlet weak var looper: UILabel!
    @IBOutlet weak var loopOnOff: UISwitch!
    @IBOutlet weak var playPause: UIButton!
    let loopSlider = LoopRangeSlider(frame: CGRectZero)
    var audioPlayer = AVAudioPlayer()
    var musicVisualizer = MusicVisualization()
    var soundWave = DrawingWaveform()
    
    //create a picker
    let musicPicker: MPMediaPickerController = MPMediaPickerController(mediaTypes: MPMediaType.Music)
    //create a music player
    let musicPlayer: MPMusicPlayerController = MPMusicPlayerController.systemMusicPlayer()
    //current song that is playing
    var currentSong = MPMediaItem()
    //to update the timeSlider
    var timer = NSTimer()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        songName.hidden = true //hide the song name
        artist.hidden = true
        looper.text = "Loop?"
        timeSlider.value = 0
        playPause.hidden = true
        playPause.enabled = false
        
        view.addSubview(timeSlider)
        view.addSubview(loopSlider) // add the loopSlider into the view
        loopSlider.addTarget(self, action: "loopSliderValueChanged:", forControlEvents: .ValueChanged)
        loopSlider.hidden = true;
        
        configureAudioSession()
        
        initMusicVisualization()
        
        configureAudioPlayer()
        
        
        //timer to update the timeSlider
        timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: Selector("updateTimeSlider"), userInfo: nil, repeats: true)
        // Do any additional setup after loading the view, typically from a nib.
    }

    //edit the frame of sliders
    override func viewDidLayoutSubviews() {
        let margin: CGFloat = 20.0
        let width = view.bounds.width - 2.0 * margin
        loopSlider.frame = CGRect(x: UIScreen.mainScreen().bounds.minX, y: UIScreen.mainScreen().bounds.midY - 20,
            width: width, height: 31.0)
        timeSlider.frame = CGRect(x: UIScreen.mainScreen().bounds.minX, y: UIScreen.mainScreen().bounds.midY,
            width: width, height: 31.0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //open up music library
    @IBAction func openMusicLibrary(sender: UIButton) {
        musicPicker.prompt = "Choose a song to import"
        musicPicker.allowsPickingMultipleItems = false
        musicPicker.delegate = self //make a copy
        
        //present it to the user
        presentViewController(musicPicker, animated: true, completion: nil)
    }
    
    //initalize MusicVisualization
    func initMusicVisualization(){
        //musicVisualizer.audioPlayer = audioPlayer
        musicVisualizer = MusicVisualization(frame: self.view.frame)
        musicVisualizer.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        view.addSubview(musicVisualizer)
        view.sendSubviewToBack(musicVisualizer)
    }
    
    //initalize DrawingWaveform
    func initDrawingWaveForm(){
        soundWave.initWithMPMediaItem(currentSong) { (delayedImagePreparation) -> Void in
            print("hi")
        }
        NSLog("\(soundWave)")
        soundWave = DrawingWaveform(frame: CGRectMake(UIScreen.mainScreen().bounds.minX, UIScreen.mainScreen().bounds.midY, 100.0, 100.0))
        //soundWave.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        view.addSubview(soundWave)
        //view.sendSubviewToBack(soundWave)
    }
    
    //when the user hit cancel
    func mediaPickerDidCancel(mediaPicker: MPMediaPickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    //after the user picked a song
    func mediaPicker(mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        songName.text = ""
        artist.text = ""
        dismissViewControllerAnimated(true, completion: nil)
        musicPlayer.setQueueWithItemCollection(mediaItemCollection) //add to the queue list
        musicPlayer.currentPlaybackTime = 0.0
        musicPlayer.prepareToPlay()
        musicPlayer.play()
        currentSong = musicPlayer.nowPlayingItem! //set currentSong to the current song
                                                  //if nil, you need to download the song from itune and make it available offline. It will return nil if it is using Home Sharing
        
        //location of the song
        let url: NSURL = currentSong.valueForProperty(MPMediaItemPropertyAssetURL) as! NSURL
        
        musicPlayer.stop()
        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
//            self.initDrawingWaveForm()
//        })
        
        playPause.hidden = false
        playPause.enabled = true
        
        //using AVAudioPlayer to play
        do{ audioPlayer = try AVAudioPlayer(contentsOfURL: url)}
        catch{
            error
            NSLog("error with audioPlayer")
        }
        audioPlayer.meteringEnabled = true
        musicVisualizer.audioPlayer = audioPlayer
        audioPlayer.prepareToPlay()
        audioPlayer.play()
        
        timeSlider.maximumValue = Float(audioPlayer.duration) //set the value for the slider
        loopSlider.maximumValue = timeSlider.maximumValue //set the value for the loop slider
        loopSlider.upperValue = timeSlider.maximumValue //move the upper thumb to the end
        
        if let songTitle: String = currentSong.valueForProperty(MPMediaItemPropertyTitle) as? String{ //get the song title
            songName.text = songTitle //set to the label
            songName.hidden = false //display the title
        }
        
        if let songArtist: String = currentSong.valueForProperty(MPMediaItemPropertyArtist) as? String {
            artist.text = songArtist
            artist.hidden = false
        }
        
        //currentSong.playbackDuration
        //let songLength: String = currentSong.valueForProperty(MPMediaItemPropertyPlaybackDuration) as! String
    }
    
    //move the slider as the song plays
    func updateTimeSlider(){
        timeSlider.value = Float(audioPlayer.currentTime)
        if loopOnOff.on{
            loop()
        }
    }
    
    //for debugging the touch for the loopRangeSlider
    func loopSliderValueChanged(rangeSlider: LoopRangeSlider) {
        print("Range slider value changed: (\(rangeSlider.lowerValue) \(rangeSlider.upperValue) \(timeSlider.value))")
    }
    
    //repeat a segment of a song
    func loop(){
        if timeSlider.value >= loopSlider.upperValue - 0.1 && timeSlider.value <= loopSlider.upperValue + 0.1{
            audioPlayer.stop()
            audioPlayer.currentTime = NSTimeInterval(loopSlider.lowerValue)
            audioPlayer.prepareToPlay()
            audioPlayer.play()
        }
    }
    
    //what to play
    func configureAudioPlayer(){
        let audioFileURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("DemoSong", ofType: "wav")!)
        do{ audioPlayer = try AVAudioPlayer(data: NSData(contentsOfURL: audioFileURL)!)}
//            do {audioPlayer = try AVAudioPlayer(contentsOfURL: audioFileURL)}
        catch{
            error
            NSLog("error with audioPlayer")
        }
       
        //audioPlayer.play()
        audioPlayer.meteringEnabled = true
        musicVisualizer.audioPlayer = audioPlayer
    }
    
    //what the system is doing
    func configureAudioSession() {
        do{ try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)}
        catch{
            NSLog("\(error)")
        }
    }
    
    //pause and play
    @IBAction func controlTheMusic(sender: UIButton) {
        switch sender.currentTitle!{
            case "Pause": audioPlayer.pause()//pause the music
                        sender.setTitle("Play", forState: .Normal)
            case "Play": audioPlayer.prepareToPlay()
                        audioPlayer.play() //play the music
                        sender.setTitle("Pause", forState: .Normal)
            default:break
        }
    }
    
    //control the time of the music
    @IBAction func changeSongTime(sender: UISlider) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        audioPlayer.pause()
        audioPlayer.currentTime = NSTimeInterval(timeSlider.value) //where to play
        audioPlayer.prepareToPlay()
        audioPlayer.play()
        playPause.setTitle("Pause", forState: .Normal)
        
        CATransaction.commit()
    }
    
    //looping option
    @IBAction func turnOnLooper(sender: UISwitch) {
        if loopOnOff.on{
            loopSlider.hidden = false
        }
        else{
            loopSlider.hidden = true
        }
    }
}


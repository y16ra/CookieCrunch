//
//  GameViewController.swift
//  CookieCrunch
//
//  Created by Ichimura Yuichi on 2015/07/31.
//  Copyright (c) 2015年 Ichimura Yuichi. All rights reserved.
//

import UIKit
import SpriteKit
import iAd

extension SKNode {
}

class GameViewController: UIViewController, ADBannerViewDelegate {

    @IBOutlet weak var adBanner: ADBannerView!
    
    var scene: GameScene!
    var level: Level!
    
    var movesLeft = 0
    var score = 0
    var currentLevel = 0
    
    @IBOutlet weak var targetLabel: UILabel!
    @IBOutlet weak var movesLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!

    @IBOutlet weak var gameOverPanel: UIImageView!
    var tapGestureRecognizer: UITapGestureRecognizer!
    
    @IBOutlet weak var shuffleButton: UIButton!
    @IBAction func shuffleButtonPressed(AnyObject) {
        shuffle()
        decrementMoves()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view.
        let skView = view as! SKView
        skView.multipleTouchEnabled = false
        //for Dubug
        //skView.showsFPS = true
        //skView.showsNodeCount = true
        
        // Show iAd Banner
        //self.canDisplayBannerAds = true
        self.adBanner.delegate = self
        self.adBanner.hidden = true
        
        // Create and configure the scene.
        scene = GameScene(size: skView.bounds.size)
        //scene = GameScene(size: skView.frame.size)
        scene.scaleMode = .AspectFill
        level = Level(filename: "Level_" + String(currentLevel))
        scene.level = level
        scene.addTiles()
        scene.swipeHandler = handleSwipe
        
        gameOverPanel.hidden = true
        
        // Present the scene.
        skView.presentScene(scene)

        beginGame()
    }
    
    func beginGame() {
        level.resetComboMultiplier()
        scene.animateBeginGame() {
            self.shuffleButton.hidden = false
        }
        shuffle()
        movesLeft = level.maximumMoves
        score = 0
        updateLabels()
    }
    
    func shuffle() {
        scene.removeAllCookieSprites()
        let newCookies = level.shuffle()
        scene.addSpritesForCookies(newCookies)
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
        } else {
            return Int(UIInterfaceOrientationMask.All.rawValue)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func handleSwipe(swap: Swap) {
        view.userInteractionEnabled = false
        
        if level.isPossibleSwap(swap) {
            level.performSwap(swap)
            scene.animateSwap(swap, completion: handleMatches)
//            scene.animateSwap(swap) {
//                self.view.userInteractionEnabled = true
//            }
        } else {
            scene.animateInvalidSwap(swap) {
                self.view.userInteractionEnabled = true
            }
        }
    }

    func handleMatches() {
        let chains = level.removeMatches()
        if chains.count == 0 {
            beginNextTurn()
            return
        }
        // TODO: do something with the chains set
        scene.animateMatchedCookies(chains) {
            
            for chain in chains {
                self.score += chain.score
            }
            self.updateLabels()
            
            let columns = self.level.fillHoles()
            self.scene.animateFallingCookies(columns) {
                let columns = self.level.topUpCookies()
                self.scene.animateNewCookies(columns) {
                    //self.view.userInteractionEnabled = true
                    self.handleMatches()
                }
            }
        }
    }
    func beginNextTurn() {
        level.resetComboMultiplier()
        level.detectPossibleSwaps()
        view.userInteractionEnabled = true
        decrementMoves()
    }
    
    func updateLabels() {
        targetLabel.text = String(format: "%ld", level.targetScore)
        movesLabel.text = String(format: "%ld", movesLeft)
        scoreLabel.text = String(format: "%ld", score)
    }
    func decrementMoves() {
        --movesLeft
        updateLabels()
        if score >= level.targetScore {
            gameOverPanel.image = UIImage(named: "LevelComplete")
            showGameOver()
        } else if movesLeft == 0 {
            gameOverPanel.image = UIImage(named: "GameOver")
            showGameOver()
        }
    }

    func showGameOver() {
        gameOverPanel.hidden = false
        scene.userInteractionEnabled = false
        shuffleButton.hidden = true
        
        // next level
        currentLevel++
        level = Level(filename: "Level_" + String(currentLevel))
        scene.level = level
        scene.removeAllTiles()
        scene.addTiles()

        scene.animateGameOver() {
            self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "hideGameOver")
            self.view.addGestureRecognizer(self.tapGestureRecognizer)
        }
    }
    func hideGameOver() {
        view.removeGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer = nil
        
        gameOverPanel.hidden = true
        scene.userInteractionEnabled = true
        
        beginGame()
    }
    
    // iAd
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        self.adBanner?.hidden = false
    }
    
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
        return willLeave
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        self.adBanner?.hidden = true
    }

    
}

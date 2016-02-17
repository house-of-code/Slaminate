//
//  ConcreteAnimation.swift
//  Slaminate
//
//  Created by Kristian Trenskow on 13/02/16.
//  Copyright © 2016 Trenskow.io. All rights reserved.
//

// Gets segmentation fault when trying to implement this as a protocol extension.

struct EventListener {
    var event: AnimationEvent
    var then: Animation -> Void
}

class ConcreteAnimation: NSObject, DelegatedAnimation {
    
    @objc(isFinished) var finished: Bool { return false }
    
    var duration: NSTimeInterval { return 0.0 }
    var delay: NSTimeInterval { return 0.0 }
    
    override init() {
        super.init()
        ongoingAnimations.append(self)
        begin()
    }
    
    @objc var position: NSTimeInterval = 0.0 {
        didSet {
            if position != oldValue {
                if position <= 0.0 {
                    progressState = .Beginning
                } else if position > 0.0 && position < delay + duration {
                    progressState = .InProgress
                } else {
                    progressState = .End
                }
            }
        }
    }
    
    var progressState: AnimationProgressState = .Beginning {
        didSet {
            if progressState != oldValue {
                owner?.childAnimation(self, didChangeProgressState: progressState)
                if progressState == .End {
                    owner?.childAnimation(self, didCompleteWithFinishState: finished)
                    emit(.End)
                    ongoingAnimations.remove(self)
                } else if oldValue == .Beginning && progressState == .InProgress || oldValue == .InProgress && progressState == .Beginning {
                    emit(.Begin)
                }
            }
        }
    }
    
    var state: AnimationState = .Waiting
    
    weak var owner: DelegatedAnimation? {
        didSet {
            if owner != nil {
                ongoingAnimations.remove(self)
                postpone()
            }
        }
    }
    
    var eventListeners = [EventListener]()
    
    private func emit(event: AnimationEvent) {
        eventListeners.filter({ $0.event == event }).forEach({ $0.then(self) })
    }
    
    @objc func on(event: AnimationEvent, then: Animation -> Void) -> Animation {
        eventListeners.append(
            EventListener(
                event: event,
                then: then
            )
        )
        return self
    }
    
    @objc func then(duration duration: NSTimeInterval, animation: Void -> Void, curve: Curve? = nil, delay: NSTimeInterval = 0.0, completion: ((finished: Bool) -> Void)? = nil) -> Animation {
        return then(animation: slaminate(
            duration: duration,
            animation: animation,
            curve: curve,
            delay: delay,
            completion: completion
        ) as! DelegatedAnimation)
    }
    
    @objc func then(animation animation: Animation) -> Animation {
        return then(animations: [animation])
    }
    
    func then(animations animations: [Animation]) -> Animation {
        return AnimationChain(animations: [self] + animations.map({ $0 as! DelegatedAnimation }))
    }
    
    @objc func then(completion completion: CompletionHandler) -> Animation {
        return AnimationChain(animations: [self, AnimationGroup(animations: [], completion: completion)])
    }
    
    @objc func and(duration duration: NSTimeInterval, animation: Void -> Void, curve: Curve? = nil, delay: NSTimeInterval = 0.0, completion: CompletionHandler? = nil) -> Animation {
        return and(animation: slaminate(
            duration: duration,
            animation: animation,
            curve: curve,
            delay: delay,
            completion: completion
        ) as! DelegatedAnimation)
    }
    
    @objc func and(animation animation: Animation) -> Animation {
        return and(animations: [animation])
    }
    
    @objc func and(animations animations: [Animation]) -> Animation {
        return AnimationGroup(
            animations: [self as DelegatedAnimation] + animations.map({ $0 as! DelegatedAnimation }),
            completion: nil
        )
    }
    
    func childAnimation(animation: Animation, didCompleteWithFinishState finished: Bool) {}
    func childAnimation(animation: Animation, didChangeProgressState: AnimationProgressState) {}
    
    func begin() {
        begin(false)
    }
    
    func begin(reversed: Bool) {
        
        guard owner == nil else {
            fatalError("Cannot begin a non-independent animation.")
        }
        
        postpone()
        
        if !reversed {
            self.performSelector(Selector("go"), withObject: nil, afterDelay: 0.0, inModes: [NSRunLoopCommonModes])
        } else {
            _ = DirectAnimation(duration: position, delay: 0.0, object: self, key: "position", toValue: 0.0, curve: Curve.linear)
        }
        
    }
    
    func postpone() -> Animation {
        NSObject.cancelPreviousPerformRequestsWithTarget(
            self,
            selector: Selector("go"),
            object: nil
        )
        return self
    }
    
    func go() {
        guard owner == nil else {
            owner?.go()
            return
        }
        commit()
    }
    
    func commit() {}
    
}

//
//  ViewController.swift
//  MNIST
//
//  Created by hakyungKim on 9/18/24.
//

import UIKit
import Sketch

class ViewController: UIViewController, SketchViewDelegate {

    @IBOutlet weak var sketchView: SketchView!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var phantImage: UIImageView!
    
    
    private var classifier: DigitClassifier?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sketchView.lineWidth = 28
        sketchView.backgroundColor = UIColor.black
        sketchView.lineColor = UIColor.white
        sketchView.sketchViewDelegate = self
        
        phantImage.layer.cornerRadius = phantImage.frame.height/2
        phantImage.layer.borderWidth = 4
        phantImage.clipsToBounds = true
        phantImage.layer.borderColor = UIColor.systemBlue.cgColor
        
        DigitClassifier.newInstance{ result in
            switch result {
            case let .success(classifier):
                self.classifier = classifier
            case .error(_):
                self.resultLabel.text = "초기화 실패"
            }
        }
        
    }
    
    // Clear라는 버튼을 누르면 => 사용자 입력을 초기화
    @IBAction func tapClear(_ sender: Any) {
        sketchView.clear()
        self.resultLabel.text = ""
    }
    
    // 사용자 입력이 끝났다는 걸 알아야 함.
    func drawView(_ view: SketchView, didEndDrawUsingTool tool: AnyObject){
        classifyDrawing()
    }
    
    private func classifyDrawing(){
        guard let classifier = self.classifier else { return }
        
        UIGraphicsBeginImageContext(sketchView.frame.size)
        sketchView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let drawing = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard drawing != nil else {
            self.resultLabel.text = "입력이 잘못되었습니다"
            return
        }
        
        classifier.classify(image: drawing!) { result in
            switch result{
            case let .success(classificationResult):
                self.resultLabel.text = classificationResult
            case .error(_):
                self.resultLabel.text = "분류시 문제가 발생"
            }
        }
        
    }
    
}


//
//  DigitClassifier.swift
//  MNIST
//
//  Created by hakyungKim on 9/20/24.
//

import TensorFlowLite

class DigitClassifier{
    private var interpreter: Interpreter
    private var inputImageWidth: Int
    private var inputImageHeight: Int
    
    // 1. 생성자
    init(interpreter: Interpreter, inputImageWidth: Int, inputImageHeight: Int){
        self.interpreter = interpreter
        self.inputImageWidth = inputImageWidth
        self.inputImageHeight = inputImageHeight
    }
    
    // 2. 백그라운드 동작을 위한 객체 설정(이미지가 계속 전달될 것)
    static func newInstance(completion: @escaping ((Result<DigitClassifier>)->Void)){
        DispatchQueue.global(qos: .background).async{
            guard let modelPath = Bundle.main.path(forResource: "new_mnist", ofType: "tflite") else {
                    DispatchQueue.main.async{
                        completion(.error(InitError.invalidModel("mnist.tflite 파일을 불러올 수 없습니다.")))
                }
                return
            }
            var options = Interpreter.Options()
            options.threadCount = 2
            
            do {
                let interpreter = try Interpreter(modelPath: modelPath, options: options)
                try interpreter.allocateTensors()
                
                let inputShape = try interpreter.input(at: 0).shape
                let inputImageWidth = inputShape.dimensions[1]
                let inputImageHeight = inputShape.dimensions[2]
                
                let classifier = DigitClassifier(interpreter: interpreter, inputImageWidth: inputImageWidth, inputImageHeight: inputImageHeight)
                
                DispatchQueue.main.async{
                    completion(.success(classifier))
                }
            } catch let error {
                DispatchQueue.main.async{
                    completion(.error(InitError.internalError(error)))
                }
                return
            }
            
        }
        
    }
    
    // 3. 분류를 진행 결과를 출력
    func classify(image: UIImage, completion: @escaping ((Result<String>)->Void)){
        DispatchQueue.global(qos: .background).async{
            let outputTensor: Tensor
            // 분류
            do {
                guard let rgbData = image.scaleData(with: CGSize(width: self.inputImageWidth, height: self.inputImageHeight)) else {
                    DispatchQueue.main.async {
                        completion(.error(ClassificationError.invalidImage))
                    }
                    return
                }
                try self.interpreter.copy(rgbData, toInputAt: 0)
                try self.interpreter.invoke()
                outputTensor = try self.interpreter.output(at: 0)
            } catch let error{
                DispatchQueue.main.async{
                    completion(.error(ClassificationError.internalError(error)))
                }
                return
            }
            //결과 전달
            let results = outputTensor.data.toArray(type: Float32.self)
            let maxConfidence = results.max() ?? -1
            let maxIndex = results.firstIndex(of: maxConfidence) ?? -1
            let result = "\(round(maxConfidence*1000)/10)%의 정확도로 이 숫자는 '\(maxIndex)' 입니다🤭"
            
            DispatchQueue.main.async{
                completion(.success(result))
            }
        }
        
        
    }
    
}

enum Result<T>{
    case success(T)
    case error(Error)
}

enum InitError: Error{
    case invalidModel(String)
    case internalError(Error)
}

enum ClassificationError: Error{
    case invalidImage
    case internalError(Error)
}

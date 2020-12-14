//
//  ContentView.swift
//  UI-72
//
//  Created by にゃんにゃん丸 on 2020/12/14.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    var body: some View {
        CameraView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct CameraView : View {
    @StateObject var camera = CameraViewModel()
    var body: some View{
        
        
        ZStack{
            
           CameraPreview(camera: camera)
                .ignoresSafeArea(.all, edges: .all)
            
            VStack{
                
                if camera.istaken{
                    HStack{
                        Spacer()
                        Button(action:camera.retake, label: {
                            
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .foregroundColor(.black)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                            
                        })
                        .padding(.trailing)
                    }
                    
                    
                }
                
                Spacer()
                
                HStack{
                    
                    if camera.istaken{
                        Button(action: {if !camera.isSaved{camera.SavePic()}}, label: {
                            Text(camera.isSaved ? "Save" : "save")
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .padding(.vertical,10)
                                .padding(.horizontal,20)
                                .background(Color.white)
                                .clipShape(Capsule())
                            
                            Spacer()
                        })
                        .padding(.leading)
                        
                        
                        
                    }
                    else{
                        
                        Button(action: camera.takePic, label: {
                            ZStack{
                                
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 65, height: 65)
                                
                                Circle()
                                    .stroke(Color.red,lineWidth: 5)
                                    .frame(width: 75, height: 75)
                            }
                        })
                    }
                    
                    
                    
                    
                }
                .frame(height: 75)
                
            }
            
            
        }
        .onAppear(perform: {
            camera.check()
        })
    }
}

class CameraViewModel : NSObject,ObservableObject,AVCapturePhotoCaptureDelegate{
    
    @Published var istaken = false
    
    @Published var session = AVCaptureSession()
    @Published var alert = false
    
    @Published var output = AVCapturePhotoOutput()
    @Published var preview : AVCaptureVideoPreviewLayer!
    
    @Published var isSaved = false
    
    @Published var picData = Data(count: 0)
    
    func check(){
        
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUP()
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (status) in
                if status{
                    self.setUP()
                }
            }
        case.denied :
            self.alert.toggle()
            
        default:
            return
        }
        
    }
    func setUP(){
        
        do{
            self.session.beginConfiguration()
            let device = AVCaptureDevice.default(.builtInDualCamera,for: .video,position: .back)
            
            
            let input = try AVCaptureDeviceInput(device: device!)
            if self.session.canAddInput(input){
                
                self.session.addInput(input)
            }
            
            if self.session.canAddOutput(self.output){
                
                self.session.addOutput(self.output)
            }
            
            self.session.commitConfiguration()
            
            
            
        }
        catch{
            print(error.localizedDescription)
        }
        
        
    }
    
    func takePic(){
        
        DispatchQueue.global(qos: .background).async {
            self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
            self.session.stopRunning()
            DispatchQueue.main.async {
                withAnimation{
                    
                    self.istaken.toggle()
                }
            }
        
            
           
        }
    }
    
    func retake(){
        
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
            DispatchQueue.main.async {
                withAnimation{
                    
                    self.istaken.toggle()
                }
                self.isSaved = false
            }
        }
    }
    
    
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil{
            
            return
        }
        print("Success")
        
        guard let imagedata = photo.fileDataRepresentation() else {return}
        
        self.picData = imagedata
        
        
       
        
        
        
    }
    
    func SavePic(){
        
        let image = UIImage(data: self.picData)!
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        self.isSaved = true
        
        print("Successfull")
        
        
        
        
    }
    
    
    
    
    
}

struct CameraPreview : UIViewRepresentable {
    
    @ObservedObject var  camera : CameraViewModel
    func makeUIView(context: Context) -> UIView {
        
        let view = UIView(frame: UIScreen.main.bounds)
        
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)
        
        camera.session.startRunning()
        
        
        
        
        return view
        
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}

//
//  ViewController.swift
//  NewPhotoKitCameraSample
//
//  Created by Dmytro Pasinchuk on 30.10.2020.
//

import UIKit
import PhotosUI

class ViewController: UIViewController {
    
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var selectImageButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func presentPhotoSelectionPicker(sender: Any) {
        showPhotoSourceMenu()
    }

}

//MARK: - Actions
extension ViewController {
    private func showPhotoSourceMenu() {
        let imageSourceAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let chooseCameraImageSourceAlertAction = UIAlertAction(title: "Camera", style: .default) { [unowned self] (_) in
            self.showCamera()
        }
        let chooseLibraryImageSourceAlertAction = UIAlertAction(title: "Photo Library", style: .default) { [unowned self] (_) in
            self.presentLibraryPicker()
        }
        imageSourceAlertController.addAction(chooseCameraImageSourceAlertAction)
        imageSourceAlertController.addAction(chooseLibraryImageSourceAlertAction)
        present(imageSourceAlertController, animated: true)
    }
    
    private func display(image: UIImage) {
        photoView.image = image
    }
    
    private func show(error: Error?) {
        let errorAlertController = UIAlertController(title: "Oops...",
                                                     message: error?.localizedDescription ?? "Something goes wrong",
                                                     preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { [unowned self] (_) in
            self.dismiss(animated: true)
        }
        errorAlertController.addAction(okAction)
        present(errorAlertController, animated: true)
    }
}

//MARK: - Camera View
extension ViewController {
    private func showCamera() {
        let accessLevel = PHAccessLevel.addOnly
        let authorizationStatus = PHPhotoLibrary.authorizationStatus(for: accessLevel)
        handleCameraAuthorizationStatus(authorizationStatus, accessLevel: accessLevel)
    }
    
    private func handleCameraAuthorizationStatus(_ authorizationStatus: PHAuthorizationStatus, accessLevel: PHAccessLevel) {
        switch authorizationStatus {
        case .notDetermined:
            requestAuthorizationForCameraUsing(accessLevel: accessLevel)
        //For .addOnly auth level .limided status will never occur, but just in case of future changes we want to show camera view even if library auth status is .limited
        case .authorized, .limited:
            presentCameraView()
        case .denied, .restricted:
            break
        @unknown default:
            fatalError()
        }
    }
    
    private func requestAuthorizationForCameraUsing(accessLevel: PHAccessLevel) {
        PHPhotoLibrary.requestAuthorization(for: accessLevel) { [weak self] (authorizationStatus) in
            DispatchQueue.main.async {
                self?.handleCameraAuthorizationStatus(authorizationStatus, accessLevel: accessLevel)
            }
        }
    }
    
    private func presentCameraView() {
        let cameraPickerController = UIImagePickerController()
        cameraPickerController.sourceType = .camera
        cameraPickerController.allowsEditing = true
        cameraPickerController.delegate = self
        present(cameraPickerController, animated: true)
    }
}

extension ViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let capturedImage = info[.editedImage] as? UIImage else {
            DispatchQueue.main.async { [weak self] in
                self?.show(error: nil)
            }
            return
        }
        //Also, we can just use this photo inside the app and did not save it to the library. In this case, we have no reason to ask about any library permission
        UIImageWriteToSavedPhotosAlbum(capturedImage, nil, nil, nil)
        display(image: capturedImage)
    }
}

//MARK: - Photo Library
extension ViewController {
    private func presentLibraryPicker() {
        var libraryPickerConfiguration = PHPickerConfiguration()
        libraryPickerConfiguration.filter = .images
        let libraryPicker = PHPickerViewController(configuration: libraryPickerConfiguration)
        libraryPicker.delegate = self
        present(libraryPicker, animated: true)
    }
}

extension ViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        if let selectedItemProvider = results.first?.itemProvider, selectedItemProvider.canLoadObject(ofClass: UIImage.self) {
            selectedItemProvider.loadObject(ofClass: UIImage.self) { [weak self] (loadedImage, error) in
                DispatchQueue.main.async {
                    guard let loadedImage = loadedImage as? UIImage, error == nil else {
                        DispatchQueue.main.async {
                            self?.show(error: error)
                        }
                        return
                    }
                    self?.display(image: loadedImage)
                }
            }
        }
    }
}

import UIKit

extension UIImage {
    func toBase64String() -> String {
        guard let imageData = self.jpegData(compressionQuality: Const.imageCompressionQuality) else {
            return ""
        }
        
        let base64String = imageData.base64EncodedString()
        
        return base64String
    }
    
    func resized() -> UIImage {
        let size = self.size
        let widthRatio = Const.imageMaxDimension / size.width
        let heightRatio = Const.imageMaxDimension / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { context in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    func compress() -> Data? {
        let quality: CGFloat = 1
        let compressedData: Data? = self.jpegData(compressionQuality: quality)
        return compressedData
    }
    
    func resizeImage(targetSize: CGFloat) -> UIImage {
        let size = self.size

        let widthRatio  = targetSize / size.width
        let heightRatio = targetSize / size.height

        let scaleFactor = min(widthRatio, heightRatio)

        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        let newRectangle = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: newRectangle)
        let newImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()

        return newImage
    }
    
}

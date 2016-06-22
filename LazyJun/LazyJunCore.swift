//
//  LazyJunCore.swift
//  
//
//  Created by TangJR on 4/25/16.
//
//

import AppKit

enum RenameType {
    case AppendPrefix
    case AppendSuffix
    case SubPrefix
    case SubSuffix
}

struct FilePathInfo {
    var fullPath: String = ""
    var suffix: String = ""
    var name: String = ""
    var subPath: String = ""
    
    var nameWithSuffix: String {
        didSet {
            guard let lastComponentInfo = Tool.splitNameAndSuffix(nameWithSuffix) else {
                return
            }
            name = lastComponentInfo.name
            suffix = lastComponentInfo.suffix
        }
    }
    
    init?(fullPath: String) {
        let fullPathObjc = fullPath as NSString
        nameWithSuffix = fullPathObjc.lastPathComponent
        self.fullPath = fullPath
        
        guard let lastComponentInfo = Tool.splitNameAndSuffix(nameWithSuffix) else {
            return nil
        }
        name = lastComponentInfo.name
        suffix = lastComponentInfo.suffix
    }
}

struct STImage {
    
    let fromFullPath: String
    
    let imageData: NSData
    let format: ImageFormat
    var fromPathInfo: FilePathInfo
    
    var image: NSImage?
    var name: String = ""
    
    init?(named fullPath: String) {
        guard let pathInfo = FilePathInfo(fullPath: fullPath) else {
            return nil
        }
        guard let fileData = NSData(contentsOfFile: fullPath) else {
            return nil
        }
        let imageFormat = fileData.imageFormat
        if imageFormat != .PNG && imageFormat != .JPEG {
            return nil
        }
        guard let originImage = NSImage(data: fileData) else {
            return nil
        }
        imageData = fileData
        fromFullPath = fullPath
        format = imageFormat
        image = originImage
        fromPathInfo = pathInfo
        name = fromPathInfo.name
    }
    
    init?(fromFullPath: String, image: NSImage, name: String, format: ImageFormat) {
        self.fromFullPath = fromFullPath
        self.image = image
        self.name = name
        self.format = format
        
        guard let data = image.toData(format), let pathInfo = FilePathInfo(fullPath: fromFullPath) else {
            return nil
        }
        self.imageData = data
        self.fromPathInfo = pathInfo
    }
}

typealias Handler = (STImage) -> STImage
typealias MutiableImageHandler = (STImage) -> [STImage]
typealias PathInfoToImageHandler = (FilePathInfo) -> STImage?

func run(fromPath: String) -> [FilePathInfo] {
    let allFilePaths = Tool.walk(fromPath, subPath: "", pathInfos: [])
    let imageFilePaths = allFilePaths.filter { pathInfo in
        return pathInfo.suffix == "png" || pathInfo.suffix == "jpg"
    }
    return imageFilePaths
}

func conver() -> PathInfoToImageHandler {
    return { pathInfo in
        let fullPath = pathInfo.fullPath
        guard var image = STImage(named: fullPath) else {
            return nil
        }
        image.fromPathInfo = pathInfo
        return image
    }
}

func compress() -> Handler {
    return { image in
        print("压缩")
        return image
    }
}

func even() -> Handler {
    return { image in
        let handledImage = image.image?.even() ?? image.image
        var imagePack = image
        imagePack.image = handledImage
        return imagePack
    }
}

func rename(type: RenameType, string: String) -> Handler {
    return { image in
        var newName = image.name
        switch type {
        case .AppendPrefix:
            newName = string + newName
        case .AppendSuffix:
            newName = newName + string
        case .SubPrefix:
            newName = Tool.subString(image.name, rangeString: string)
        case .SubSuffix:
            newName = Tool.subString(image.name, rangeString: string, options: .BackwardsSearch)
        }
        var newImage = image
        newImage.name = newName
        return newImage
    }
}

func generate2x() -> Handler {
    return { image in
        guard let handledImage = image.image else {
            return image
        }
        let width = handledImage.size.width
        let height = handledImage.size.height
        let proportion: CGFloat = 2.0 / 3.0
        
        let newWidth = Tool.evenNumber(width * proportion)
        let newHeight = Tool.evenNumber(height * proportion)
        
        var imagePack = image
        imagePack.image = handledImage.resize(CGSize(width: newWidth, height: newHeight))
        return imagePack
    }
}

func generateSize(sizes: [CGSize]) -> MutiableImageHandler {
    return { image in
        guard let handledImage = image.image else {
            return [image]
        }
        var icons: [STImage] = []
        for size in sizes {
            let icon = handledImage.resize(size)
            guard let iconPack = STImage(fromFullPath: image.fromFullPath, image: icon, name: size.toString(), format: image.format) else {
                continue
            }
            icons.append(iconPack)
        }
        return icons
    }
}

func save(imagePack: STImage, toPath: String) {
    print("存储" + imagePack.name)
    Tool.saveImageToPath(toPath, imagePack: imagePack, format: imagePack.format)
}

infix operator >|< {associativity left}
func >|<(lhs: Handler, rhs: Handler) -> Handler {
    return { image in
        rhs(lhs(image))
    }
}

infix operator => {associativity left}
func =>(lhs: Handler, rhs: [FilePathInfo]) {
    let toPath = "/Users/tangjr/Desktop/" + Tool.currentDateToPath()
    for pathInfo in rhs {
        guard let image = conver()(pathInfo) else {
            return
        }
        let handledImage = lhs(image)
        save(handledImage, toPath: toPath)
    }
}

infix operator ==> {associativity left}
func ==>(lhs: MutiableImageHandler, rhs: [FilePathInfo]) {
    let toPath = NSSearchPathForDirectoriesInDomains(.DesktopDirectory, .UserDomainMask, true)[0] + Tool.currentDateToPath()
    for pathInfo in rhs {
        guard let image = conver()(pathInfo) else {
            return
        }
        let handledImages = lhs(image)
        for var imagePack in handledImages {
            imagePack.fromPathInfo = pathInfo
            imagePack.fromPathInfo.subPath = (imagePack.fromPathInfo.subPath as NSString).stringByAppendingPathComponent(pathInfo.name)
            save(imagePack, toPath: toPath)
        }
    }
}

struct Tool {
    static func walk(rootPath: String, subPath: String, pathInfos: [FilePathInfo]) -> [FilePathInfo] {
        let fileManager = NSFileManager.defaultManager()
        let fullPath = (rootPath as NSString).stringByAppendingPathComponent(subPath)
        if !fullPath.isDir() {
            if fileManager.fileExistsAtPath(fullPath) {
                guard let pathI = FilePathInfo(fullPath: fullPath) else {
                    return []
                }
                return [pathI]
            }
            return []
        }
        let files = try! fileManager.contentsOfDirectoryAtPath(fullPath)
        var pathInfos: [FilePathInfo] = []
        
        for name in files {
            let path = ((rootPath as NSString).stringByAppendingPathComponent(subPath) as NSString).stringByAppendingPathComponent(name)
            guard var pathInfo = FilePathInfo(fullPath: path) else {
                continue
            }
            pathInfo.subPath = subPath
            pathInfos.append(pathInfo)
            if path.isDir() {
                pathInfos += walk(rootPath, subPath: subPath + name, pathInfos: pathInfos)
            }
        }
        return pathInfos
    }
    
    static func splitNameAndSuffix(subPath: String) -> (name: String, suffix: String)? {
        let subPathObjc = subPath as NSString
        if subPath == "" {
            return nil
        }
        let suffix = subPathObjc.pathExtension
        if suffix == "" {
            return (subPath, suffix)
        }
        var name = subPath
        name.removeRange(subPath.rangeOfString("." + suffix, options: .BackwardsSearch)!)
        return (name, suffix)
    }
    
    static func evenNumber(number: CGFloat) -> CGFloat {
        let ceilNumber = ceil(number)
        return ceilNumber % 2 == 0 ? ceilNumber : ceilNumber + 1
    }
    
    static func saveImageToPath(path: String, imagePack: STImage, format: ImageFormat) {
        let fileManager = NSFileManager.defaultManager()
        let toPathObjc = path as NSString
        let folderPath = toPathObjc.stringByAppendingPathComponent(imagePack.fromPathInfo.subPath)
        let isExist = fileManager.fileExistsAtPath(folderPath)
        if !isExist {
            try! fileManager.createDirectoryAtPath(folderPath, withIntermediateDirectories: true, attributes: nil)
        }
        let toPath = (folderPath as NSString).stringByAppendingPathComponent(imagePack.name + "." + imagePack.fromPathInfo.suffix)
        fileManager.createFileAtPath(toPath, contents: imagePack.imageData, attributes: nil)
    }
    
    static func currentDateToPath() -> String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh-mm-ss"
        let dateString = formatter.stringFromDate(NSDate())
        return dateString
    }
    
    static func subString(string: String, rangeString: String, options: NSStringCompareOptions = .CaseInsensitiveSearch) -> String {
        guard let range = string.rangeOfString(rangeString, options: options) else {
            return string
        }
        var newString = string
        newString.removeRange(range)
        return newString
    }
}

extension String {
    func isDir() -> Bool {
        let fileManager = NSFileManager.defaultManager()
        var isDirObjc = false as ObjCBool
        let isExist = fileManager.fileExistsAtPath(self, isDirectory: &isDirObjc)
        return (isExist && isDirObjc)
    }
}

extension CGSize {
    func toString() -> String {
        return "\(Int(width))_\(Int(height))"
    }
}

extension NSImage {
    func resize(newSize: NSSize) -> NSImage {
        let retinaSize = NSMakeSize(newSize.width / 2.0, newSize.height / 2.0)
        let newImage = NSImage(size: retinaSize)
        newImage.lockFocus()
        size = retinaSize
        NSGraphicsContext.currentContext()?.imageInterpolation = .High
        drawAtPoint(NSZeroPoint, fromRect: NSMakeRect(0, 0, retinaSize.width, retinaSize.height), operation: .CompositeCopy, fraction: 1.0)
        
        newImage.unlockFocus()
        return newImage
    }
    
    func even() -> NSImage {
        let width = size.width
        let height = size.height
        
        let pluralWidth = Tool.evenNumber(width) / 2.0
        let pluralHeight = Tool.evenNumber(height) / 2.0
        
        let pluralSize = NSMakeSize(pluralWidth, pluralHeight)
        
        let newImage = NSImage(size: pluralSize)
        
        newImage.lockFocus()
        size = pluralSize
        NSGraphicsContext.currentContext()?.imageInterpolation = .High
        drawAtPoint(NSZeroPoint, fromRect: NSMakeRect(0, 0, width, height), operation: .CompositeCopy, fraction: 1.0)
        
        newImage.unlockFocus()
        
        return newImage
    }
    
    func toData(format: ImageFormat) -> NSData? {
        let data: NSData?
        switch format {
        case .PNG: data = ImagePNGRepresentation(self)
        case .JPEG: data = ImageJPEGRepresentation(self, 1.0)
        case .GIF, .Unknown : data = nil
        }
        return data
    }
}

// MARK: - PNG
func ImagePNGRepresentation(image: NSImage) -> NSData? {
    #if os(OSX)
        if let cgimage = image.CGImage {
            let rep = NSBitmapImageRep(CGImage: cgimage)
            return rep.representationUsingType(.NSPNGFileType, properties:[:])
        }
        return nil
    #else
        return UIImagePNGRepresentation(image)
    #endif
}

// MARK: - JPEG
func ImageJPEGRepresentation(image: NSImage, _ compressionQuality: CGFloat) -> NSData? {
    #if os(OSX)
        let rep = NSBitmapImageRep(CGImage: image.CGImage)
        return rep.representationUsingType(.NSJPEGFileType, properties: [NSImageCompressionFactor: compressionQuality])
    #else
        return UIImageJPEGRepresentation(image, compressionQuality)
    #endif
}

extension NSImage {
    var CGImage: CGImageRef! {
        return CGImageForProposedRect(nil, context: nil, hints: nil)
    }
}

// ImageFormat

private let pngHeader: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
private let jpgHeaderSOI: [UInt8] = [0xFF, 0xD8]
private let jpgHeaderIF: [UInt8] = [0xFF]
private let gifHeader: [UInt8] = [0x47, 0x49, 0x46]

enum ImageFormat {
    case Unknown, PNG, JPEG, GIF
}

extension NSData {
    var imageFormat: ImageFormat {
        var buffer = [UInt8](count: 8, repeatedValue: 0)
        self.getBytes(&buffer, length: 8)
        if buffer == pngHeader {
            return .PNG
        }
        if buffer[0] == jpgHeaderSOI[0] && buffer[1] == jpgHeaderSOI[1] && buffer[2] == jpgHeaderIF[0] {
            return .JPEG
        }
        if buffer[0] == gifHeader[0] && buffer[1] == gifHeader[1] && buffer[2] == gifHeader[2] {
            return .GIF
        }
        return .Unknown
    }
}
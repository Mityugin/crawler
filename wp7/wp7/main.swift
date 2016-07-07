import Foundation


func matchesForRegexInText(regex: String, text: String) -> [String] {
    do {
        let regex = try RegularExpression(pattern: regex, options: [.caseInsensitive])
        let range = NSMakeRange(0, text.characters.count)
        let results = regex.matches(in: text, options: [], range: range)
        let nsString = text as NSString
        let urls: [String] = results.map { result in
            return nsString.substring(with: result.range(at: 1))
        }
        return urls
    } catch let error as NSError {
        print("invalid regex: \(error.localizedDescription)")
        return []
    }
}


let domain = "mityugin.com"
let htp = "http://"
let searchStr = "15 лет"

let url = htp+domain
let session = URLSession.shared()
let request = URLRequest(url: URL(string: url)!)
let task = session.dataTask(with: request, completionHandler: {
    (data, response, error) -> Void in
    
    var usedEncoding =  String.Encoding.utf8 // Some fallback value
        
    if let encodingName = response?.textEncodingName {

        let encoding = CFStringConvertIANACharSetNameToEncoding(encodingName)
        if encoding != kCFStringEncodingInvalidId {
            
            usedEncoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(encoding))
            
        }
    }
    
    if let myString = String(data: data!, encoding: usedEncoding) {
        do {
            try myString.write(toFile: "\(domain).html", atomically: true, encoding: usedEncoding)
        } catch {
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
        }
        let matches = matchesForRegexInText(regex: "href=\"([^\"]*?)\"", text: myString)
        var pageUrls: Set<String> = []
        
        for var matchStr in matches {
            if (matchStr.hasPrefix(url) || matchStr.hasPrefix("/")) && !(matchStr.hasSuffix(".png") || matchStr.hasSuffix(".jpg") || matchStr.hasSuffix("/")) && matchStr != url {
                if matchStr.hasPrefix("/") {
                    matchStr = url+matchStr
                }
                pageUrls.insert(matchStr)
                
            }
        
        }
        
        let lineset = pageUrls.sorted().joined(separator: ",")
        do {
            try lineset.write(toFile: "\(domain).links", atomically: true, encoding: usedEncoding)
        } catch {
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
        }
        
        // Search for one string in another.
        var result = myString.range(of: searchStr, options: NSString.CompareOptions.literalSearch, range: myString.startIndex..<myString.endIndex, locale: nil)
        
        // See if string was found.
        if let range = result {
            
            // Display range.
            
            let start = range.lowerBound
            let end = myString.index(start, offsetBy: 140)
            let mySubString = myString.substring(with: start..<end)
            
            do {
                try mySubString.write(toFile: "\(domain).search", atomically: true, encoding: usedEncoding)
            } catch {
                // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
            }
  
            
        }
    } else {
        print("failed to decode data")
    }
})

// Running URLSession
task.resume()

// Terminate execution with CTRL+C
RunLoop.main().run()

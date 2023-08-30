//  Created by Steven Curtis

extension Dictionary where Key: CustomStringConvertible {
    func parameters() -> String {
          var paramsString: [String] = []

          for (key, value) in self {
              let keyString = key.description
              let valueString: String
              
              if let stringValue = value as? String {
                  valueString = stringValue
              } else if let intValue = value as? Int {
                  valueString = "\(intValue)"
              } else if let doubleValue = value as? Double {
                  valueString = "\(doubleValue)"
              } else {
                  continue
              }
              
              if let encodedKey = keyString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                 let encodedValue = valueString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                  paramsString.append("\(encodedKey)=\(encodedValue)")
              }
          }
          return paramsString.joined(separator: "&")
      }
  }

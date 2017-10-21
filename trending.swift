#!/usr/bin/swift

// # <bitbar.title>Trending Swift on GitHub</bitbar.title>
// # <bitbar.version>v1.0</bitbar.version>
// # <bitbar.author>Reda Lemeden</bitbar.author>
// # <bitbar.author.github>kaishin</bitbar.author.github>
// # <bitbar.desc>List trending GitHub repositories in a given period.</bitbar.desc>
// # <bitbar.image>http://www.hosted-somewhere/pluginimage</bitbar.image>
// # <bitbar.dependencies>swift</bitbar.dependencies>
// # <bitbar.abouturl>http://url-to-about.com/</bitbar.abouturl>

import Foundation

infix operator =~

func =~ (value: String, pattern: String) -> RegexResult {
  var error: NSError?
  let string = value as NSString
  let options = NSRegularExpression.Options(rawValue: 0)
  let regex: NSRegularExpression?

  do {
    regex = try NSRegularExpression(pattern: pattern, options: options)
  } catch let error1 as NSError {
    error = error1
    regex = nil
  }

  if error != nil { return RegexResult(results: []) }

  let all = NSRange(location: 0, length: string.length)
  let matchingOptions = NSRegularExpression.MatchingOptions(rawValue: 0)
  var matches: [String] = []

  regex?.enumerateMatches(in: value, options: matchingOptions, range: all) { result, _, _ in
    guard let result = result else { return }
    let subString = string.substring(with: result.range)
    matches.append(subString)
  }

  return RegexResult(results: matches)
}

struct RegexResult {
  let isMatching: Bool
  let matches: [String]

  init(results: [String]) {
    matches = results
    isMatching = matches.count > 0
  }
}

extension String {
   func matches(pattern: String) -> [String] {
    let regexResult = (self =~ pattern)

    if regexResult.isMatching {
      return regexResult.matches
    } else {
      return []
    }
  }

  func condenseWhitespace() -> String {
    let components = self.components(separatedBy: NSCharacterSet.whitespacesAndNewlines)
    return components.filter { !$0.isEmpty }.joined(separator: " ")
  }
}

extension Array {
  func chunk(_ chunkSize: Int) -> [[Element]] {
    return stride(from: 0, to: self.count, by: chunkSize).map({ (startIndex) -> [Element] in
      let endIndex = (startIndex.advanced(by: chunkSize) > self.count) ? self.count-startIndex : chunkSize
      return Array(self[startIndex..<startIndex.advanced(by: endIndex)])
    })
  }
}

struct Repository {
  let authorName: String
  let projectName: String
  let description: String
  let starCount: Int
  let starredInPeriod: String

  init?(string: String) {
    let properties = string.split(separator: "|")
    if properties.count != 4 { return nil }

    self.authorName = String(describing: properties[0].split(separator: "/").first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    self.projectName = String(describing: properties[0].split(separator: "/").last ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

    let fullDescription = String(describing: properties[1]).trimmingCharacters(in: .whitespacesAndNewlines)
    let fullDescriptionWords = fullDescription.split(separator: " ")
    let chunkedDescription = fullDescriptionWords.chunk(8).map { chunk in
      return chunk.joined(separator: " ")
    }

    self.description = chunkedDescription.joined(separator: "| size=12 \n")

    let stars = String(describing: properties[2].split(separator: " ").first?.replacingOccurrences(of: ",", with: "") ?? "0")
    self.starCount = Int(stars) ?? 0

    self.starredInPeriod = String(describing: properties[3]).trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var gitHubURL: String {
    return "https://github.com/\(authorName)/\(projectName)/"
  }
}


// Remote
let url = URL(string: "https://github.com/trending/swift")!
let html = try? String(contentsOf: url)


let repos = html?.matches(pattern: "<ol class=\"repo-list\">(.|\n)*?</ol>")[0]
let repoList = repos?.matches(pattern: "<li class=(.|\n)*?</li>")
var repositories = [Repository]()

repositories = (repoList ?? []).flatMap { repo in
  let sanitizedString = repo.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    .replacingOccurrences(of: "\n    Star|Built by\n|\n          Swift", with: "|", options: .regularExpression)
    .condenseWhitespace()

    return Repository(string: sanitizedString)
  }

print("| size=10 templateImage=iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAATBJREFUeNqc0b1KQzEYxvFQq4i2kwiCDjo4dZIKQm+hm5tUUHDxBnQSF1cXh1IR3AqdBK+gLl5BURz82hy0Iq2lYkHqP/BGHsKxFgM/Tvvk5D3Jm7Rzro8OHtHABc7x6oYc/QSfqCH33wLBF8rIDiowj2Ws4wQvCYVuh92NH6NW7D4q8oaVpAVH2EMRk5KP4zChSG5QD/xtVDAr82voRcfJ/tXEd5SiIjpfDhMjmEETc0hbPoZVu85LXNlXCzafx5k1/GdMYAet6Gsl6Yk2tvbbLSziLjpO6MmG5L4vU7rIbysl/9vy8rFccVPyLR/uS1CXPuxGt5Ox/FTyqrMt6plDo/yCD8mLlm9K1kjZVnW07NmxGwhjyZ43ki34Att4QhcHuJYXHuT3tD2fJct8CzAAqHZ3QQFiFvsAAAAASUVORK5CYII=")
print("---")
for repo in repositories {

  print("\(repo.authorName)/\(repo.projectName)", "| href=\(repo.gitHubURL)")
  print(repo.description, "| size=12")
  print("---")
}

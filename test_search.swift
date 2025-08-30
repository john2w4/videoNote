import Foundation

func parseSearchTerms(_ query: String) -> [String] {
    let separators = CharacterSet(charactersIn: ",，")
    
    let terms = query
        .components(separatedBy: separators)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    
    if terms.count == 1 && terms.first == query.trimmingCharacters(in: .whitespacesAndNewlines) {
        return [query.trimmingCharacters(in: .whitespacesAndNewlines)]
    }
    
    return terms
}

// 测试用例
let test1 = "hello,world"
let test2 = "你好，世界"
let test3 = "单个词"
let test4 = "word1,word2,word3"

print("Test 1: \"\(test1)\" -> \(parseSearchTerms(test1))")
print("Test 2: \"\(test2)\" -> \(parseSearchTerms(test2))")
print("Test 3: \"\(test3)\" -> \(parseSearchTerms(test3))")
print("Test 4: \"\(test4)\" -> \(parseSearchTerms(test4))")

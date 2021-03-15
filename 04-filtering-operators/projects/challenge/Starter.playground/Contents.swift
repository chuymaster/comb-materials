import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "challenge") {
    let numbers = (1...100).publisher
    
    numbers
        .dropFirst(50)
        .prefix(20)
        .filter { $0 % 2 == 0 }
        .sink { value in
            print(value)
        }.store(in: &subscriptions)
    
}

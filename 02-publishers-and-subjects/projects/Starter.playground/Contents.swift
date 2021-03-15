import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "Publisher") {
    let myNotification = Notification.Name("MyNotification")
    
    let publisher = NotificationCenter.default.publisher(for: myNotification, object: nil)
    
    let center = NotificationCenter.default
    
    let observer = center.addObserver(forName: myNotification,
                                      object: nil,
                                      queue: nil) { notification in
        print("received!")
    }
    
    center.post(name: myNotification, object: nil)
    
    center.removeObserver(observer)
}

example(of: "Subscriber") {
    let myNotification = Notification.Name("MyNotification")
    
    let publisher = NotificationCenter.default.publisher(for: myNotification, object: nil)
    
    let center = NotificationCenter.default
    
    let subscription = publisher.sink { _ in
        print("received from publisher!")
    }
    
    center.post(name: myNotification, object: nil)
    
    subscription.cancel()
}

example(of: "Just") {
  // 1
  let just = Just("Hello world!")
  
  // 2
  _ = just
    .sink(
      receiveCompletion: {
        print("Received completion", $0)
      },
      receiveValue: {
        print("Received value", $0)
    })
}

example(of: "assign(to:on:)") {
  // 1
  class SomeObject {
    var value: String = "" {
      didSet {
        print(value)
      }
    }
  }
  
  // 2
  let object = SomeObject()
  
  // 3
  let publisher = ["Hello", "world!"].publisher
  
  // 4
  _ = publisher
    .assign(to: \.value, on: object)
}

example(of: "assign(to:") {
    // 1
    class SomeObject {
        @Published var value = 0
    }
    
    // 2
    let object = SomeObject()
    
    // 3
    object.$value
        .sink {
            print($0)
        }
    
//    “Use the $ prefix on the @Published property to gain access to its underlying publisher, subscribe to it, and print out each value received.
//    Create a publisher of numbers and assign each value it emits to the value publisher of object. Note the use of & to denote an inout reference to the property.”
//
//    Excerpt From: By Marin Todorov. “Combine: Asynchronous Programming with Swift.” Apple Books.
    
    // 4
    (0..<10).publisher
        .assign(to: &object.$value)
    
    [0,1,2,3].publisher
        .assign(to: &object.$value)
}

example(of: "Custom Subscriber") {
    let publisher = (1...6).publisher
//    let publisher = ["a","b"].publisher
    
    final class IntSubscriber: Subscriber {
        typealias Input = Int
        typealias Failure = Never
        
        func receive(subscription: Subscription) {
            //“ the subscriber is willing to receive up to three values upon subscription.”
            subscription.request(.max(3))
        }
        
        func receive(_ input: Int) -> Subscribers.Demand {
            print("Received value", input)
            return .none
        }
        
        func receive(completion: Subscribers.Completion<Never>) {
            print("Received completion", completion)
        }
    }
    
    let subscriber = IntSubscriber()
    
    publisher.subscribe(subscriber)
}

//example(of: "Future") {
//    func futureIncrement(
//        integer: Int,
//        afterDelay delay: TimeInterval) -> Future<Int, Never> {
//        Future<Int, Never> { promise in
//            print("Original")
//            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
//                promise(.success(integer + 1))
//            }
//        }
//    }
//
//    let future = futureIncrement(integer: 1, afterDelay: 3)
//
//    future.sink(receiveCompletion: { print($0) }, receiveValue: { print($0) })
//        .store(in: &subscriptions)
//
//    future.sink(receiveCompletion: { print("Second", $0) }, receiveValue: { print("Second", $0) })
//        .store(in: &subscriptions)
//}


example(of: "PassthroughSubject") {
  // 1
  enum MyError: Error {
    case test
  }
  
  // 2
  final class StringSubscriber: Subscriber {
    typealias Input = String
    typealias Failure = MyError
    
    func receive(subscription: Subscription) {
      subscription.request(.max(2))
    }
    
    func receive(_ input: String) -> Subscribers.Demand {
      print("Received value", input)
      // 3
      return input == "World" ? .max(1) : .none
    }
    
    func receive(completion: Subscribers.Completion<MyError>) {
      print("Received completion", completion)
    }
  }
  
  // 4
  let subscriber = StringSubscriber()
    
    let subject = PassthroughSubject<String, MyError>()
    
    subject.subscribe(subscriber)
    
    let subscription = subject
        .sink { (completion) in
            print("Received completion (sink)", completion)
        } receiveValue: { (value) in
            print("Received value (sink)", value)
        }

    subject.send("Hello")
    
    subject.send("World")
    
    subscription.cancel()
    
    subject.send("Hey there")
    
    subject.send(completion: .failure(MyError.test))
    subject.send(completion: .finished)
    
    subject.send("Hey there 2")
    
}

example(of: "CurrentValueSubject") {
  // 1
  var subscriptions = Set<AnyCancellable>()
  
  // 2
  let subject = CurrentValueSubject<Int, Never>(0)
  
  // 3
  subject
    .print()
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions) // 4
    
    
    subject.send(1)
    subject.send(2)
    
    print(subject.value)
    
    subject
        .print()
        .sink(receiveValue: { print("Second subscription: ", $0)})
        .store(in: &subscriptions)
    
    subject.send(completion: .finished)
    
}

example(of: "Dynamically adjusting Demand") {
  final class IntSubscriber: Subscriber {
    typealias Input = Int
    typealias Failure = Never
    
    func receive(subscription: Subscription) {
      subscription.request(.max(2))
    }
    
    func receive(_ input: Int) -> Subscribers.Demand {
      print("Received value", input)
      
      switch input {
      case 1:
        return .max(2) // 1
      case 3:
        return .max(1) // 2
      default:
        return .none // 3
      }
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
      print("Received completion", completion)
    }
  }
  
  let subscriber = IntSubscriber()
  
  let subject = PassthroughSubject<Int, Never>()
  
  subject.subscribe(subscriber)
  
  subject.send(1)
  subject.send(2)
  subject.send(3)
  subject.send(4)
  subject.send(5)
  subject.send(6)
}

example(of: "Type erasure") {
  // 1
  let subject = PassthroughSubject<Int, Never>()
  
  // 2
  let publisher = subject.eraseToAnyPublisher()
  
  // 3
  publisher
    .print()
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
  
  // 4
  subject.send(0)
}


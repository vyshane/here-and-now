import XCTest
import Mockingjay
import RxBlocking
@testable import Here___Now

class WebServiceTests: XCTestCase, WebService {
    
    struct FooBar: Decodable, Equatable {
        var foo: String
        override static func == (left: FooBar, right: FooBar) -> Bool {
            return left.foo == right.foo
        }
    }
    
    func testGetAndDecode() {
        stub(uri("http://localhost/api/test/foobar"), json([ "foo": "bar" ]))
        let url = URL(string: "http://localhost/api/test/foobar")
        let response: FooBar = try! get(url: url!).toBlocking().single()
        XCTAssertEqual(response, FooBar(foo: "bar"))
    }
}

import XCTest
import Mockingjay
import Nimble
import RxBlocking
@testable import HereAndNow

class WebServiceTests: XCTestCase, WebService {
    
    let serviceUri = "http://localhost/api/test/foobar"

    struct DecodableResponse: Decodable, Equatable {
        var foo: String
        override static func == (left: DecodableResponse, right: DecodableResponse) -> Bool {
            return left.foo == right.foo
        }
    }
    
    func testGetAndDecode() {
        stub(uri(serviceUri), json([ "foo": "bar" ]))
        let response: DecodableResponse = try! get(url: URL(string: serviceUri)!).toBlocking().first()!
        expect(response) == DecodableResponse(foo: "bar")
    }
    
    func testGetFailure() {
        stub(uri(serviceUri), http(500))
        expect(try self.get(url: URL(string: self.serviceUri)!).toBlocking().first()!).to(throwError())
    }
}

import Foundation
import RxSwift

public typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void

enum WebServiceError: Error {
    case cantParseJSON
}

protocol WebService {
    func get<A: Decodable>(url: URL, session: URLSession) -> Single<A>
    func get(url: URL, session: URLSession) -> Single<(Data, URLResponse)>
}

extension WebService {

    func get<A: Decodable>(url: URL, session: URLSession = URLSession.shared) -> Single<A> {
        return get(url: url, session: session).flatMap({ pair in
            do {
                let a = try JSONDecoder().decode(A.self, from: pair.0)
                return Single.just(a)
            } catch {
                return Single.error(error)
            }
        })
    }
    
    func get(url: URL, session: URLSession = URLSession.shared) -> Single<(Data, URLResponse)> {
        return Single.create { observer in
            let task = session.dataTask(with: url, completionHandler: self.handleResponse(observer))
            task.resume()
            return Disposables.create { task.cancel() }
        }
    }
    
    private func handleResponse(_ observer: @escaping (SingleEvent<(Data, URLResponse)>) -> ()) -> CompletionHandler {
        return { data, response, error in
            if let error = error {
                observer(.error(error))
                return
            }
            observer(.success((data!, response!)))
        }
    }
}

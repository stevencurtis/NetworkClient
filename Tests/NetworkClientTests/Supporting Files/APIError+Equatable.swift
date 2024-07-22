import NetworkClient

extension APIError: Equatable {
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        lhs.errorDescription == rhs.errorDescription
    }
}

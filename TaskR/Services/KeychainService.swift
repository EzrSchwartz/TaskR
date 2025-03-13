import Security
import Foundation

struct KeychainService {
    
    static func saveCredentials(email: String, password: String) {
        let credentials = Credentials(email: email, password: password)
        if let data = try? JSONEncoder().encode(credentials) { // ✅ Now Encodable
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: "userCredentials",
                kSecValueData as String: data
            ]
            SecItemDelete(query as CFDictionary) // Remove old credentials
            SecItemAdd(query as CFDictionary, nil)
        }
    }
    
    static func loadCredentials() -> Credentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userCredentials",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &dataTypeRef) == noErr,
           let data = dataTypeRef as? Data,
           let credentials = try? JSONDecoder().decode(Credentials.self, from: data) { // ✅ Decode properly
            return credentials
        }
        return nil
    }
}

struct Credentials: Codable {
    let email: String
    let password: String
}

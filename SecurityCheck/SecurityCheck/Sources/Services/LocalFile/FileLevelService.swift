//
//  FileLevelService.swift
//  SecurityCheck
//
//  Created by Matija Kruljac on 26.04.2023..
//

import CryptoSwift
import Foundation

final class FileLevelService {

    static let shared: FileLevelService = FileLevelService()

    // AWS Key and IV
    private let aesKey: String = "keykeykeykeykeyk"
    private let aesIV: String = "drowssapdrowssap"

    private init() {}
}

// MARK: - Public methods
extension FileLevelService {

    // Encrypt a file using the encryption key
    func encryptFile(at url: URL) throws {
        let plaintextData = try Data(contentsOf: url)
        let aes = try AES(key: self.aesKey, iv: self.aesIV)
        let encryptedBytes = try aes.encrypt(plaintextData.bytes)
        let encryptedData = Data(encryptedBytes)
        let encryptedDataAsText = String(decoding: encryptedData, as: UTF8.self)
        try encryptedDataAsText.write(to: url, atomically: false, encoding: .utf8)
    }

    // Decrypt a file using the encryption key
    func decryptFile(at url: URL) throws {
        let encryptedData = try Data(contentsOf: url)
        let aes = try AES(key: self.aesKey, iv: self.aesIV)
        let decryptedBytes = try aes.decrypt(encryptedData.bytes)
        let decryptedData = Data(decryptedBytes)
        let decryptedText = String(decoding: decryptedData, as: UTF8.self)
        try decryptedText.write(to: url, atomically: false, encoding: .utf8)
    }
}

//
//  ViewController.swift
//  SecurityCheck
//
//  Created by Matija Kruljac on 25.04.2023..
//

import CryptoSwift
import UIKit

class ViewController: UIViewController {

    private let aesKeyKey: String = "aes_key_key"
    private let aesIVKey: String = "aes_iv_key"

    private let aesKey: String = "keykeykeykeykeyk"
    private let aesIV: String = "drowssapdrowssap"

    private let testObjectKey: String = "test_object_key"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        testCoreDataService()
        testKeychainService()
        testFileLevelService()
    }
}

// MARK: - Private methods
private extension ViewController {

    func testCoreDataService() {
        print("Clearing CoreData model...")
        CoreDataService.shared.delete(type: TestManagedObject.self)
        CoreDataService.shared.delete(type: EncryptedDataMO.self)

//        CoreDataService.shared.create {
//            let newTestManagedObject1 = CoreDataMOFactory.create(type: TestManagedObject.self)
//            newTestManagedObject1.property1 = 111
//            newTestManagedObject1.property2 = "test_managed_object_1"
//
//            let newTestManagedObject2 = CoreDataMOFactory.create(type: TestManagedObject.self)
//            newTestManagedObject2.property1 = 222
//            newTestManagedObject2.property2 = "test_managed_object_2"
//
//            let newTestManagedObject3 = CoreDataMOFactory.create(type: TestManagedObject.self)
//            newTestManagedObject3.property1 = 333
//            newTestManagedObject3.property2 = "test_managed_object_3"
//
//            let newTestManagedObject4 = CoreDataMOFactory.create(type: TestManagedObject.self)
//            newTestManagedObject4.property1 = 444
//            newTestManagedObject4.property2 = "test_managed_object_4"
//
//            let newTestManagedObject5 = CoreDataMOFactory.create(type: TestManagedObject.self)
//            newTestManagedObject5.property1 = 555
//            newTestManagedObject5.property2 = "test_managed_object_5"
//        }
//
//        CoreDataService.shared.read(type: TestManagedObject.self) { result in
//            print("\n")
//            print("------- CoreData -------")
//
//            result.forEach { testManagedObject in
//                print(testManagedObject.property1)
//                print(testManagedObject.property2 ?? "")
//            }
//        }

        CoreDataService.shared.create { [weak self] in
            guard let self else {
                return
            }

            do {
                let textToEncrypt = "TEXT TO ENCRYPT"
                let textToEncryptData = Data(textToEncrypt.utf8)

                // Encrypt Data
                let aes = try AES(key: self.aesKey, iv: self.aesIV)
                let encryptedBytes = try aes.encrypt(textToEncryptData.bytes)
                let encryptedData = Data(encryptedBytes)

                let encryptedDataMO = CoreDataMOFactory.create(type: EncryptedDataMO.self)
                encryptedDataMO.data = encryptedData
                print("Encrypted data for |\(textToEncrypt)|: \(encryptedData.toHexString())")

            } catch let error {
                fatalError("AES encrpytion failed \(error)")
            }
        }

        CoreDataService.shared.read(type: EncryptedDataMO.self) { [weak self] result in
            print("\n")

            guard let self else {
                return
            }

            result.forEach { encryptedDataMO in
                guard let encryptedDataMOData = encryptedDataMO.data else {
                    return
                }

                do {
                    // Decrypt Data
                    let aes = try AES(key: self.aesKey, iv: self.aesIV)
                    let decryptedBytes = try aes.decrypt(encryptedDataMOData.bytes)
                    let decryptedData = Data(decryptedBytes)
                    let decryptedText = String(decoding: decryptedData, as: UTF8.self)
                    print("Decrypted text for |\(encryptedDataMOData.toHexString())|: \(decryptedText)")
                } catch let error {
                    fatalError("AES decrpytion failed \(error)")
                }
            }
        }
    }

    func testKeychainService() {
        print("\n")
        print("------- Keychain -------")

        // Strings
        if KeychainService.shared.setString(aesKey, forKey: aesKeyKey) {
            let value: String? = KeychainService.shared.getString(forKey: aesKeyKey)
            print("AES Key: \(value ?? "")")
        }

        if KeychainService.shared.setString(aesIV, forKey: aesIVKey) {
            let value: String? = KeychainService.shared.getString(forKey: aesIVKey)
            print("AES IV: \(value ?? "")")
        }

        // Data
        let testObject = TestObject(property1: 111, property2: "test")

        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: testObject, requiringSecureCoding: false)
            
            if KeychainService.shared.saveDataToKeychain(data: data, forKey: testObjectKey) {
                if let data: Data = KeychainService.shared.getDataFromKeychain(forKey: testObjectKey),
                   let testObject = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? TestObject {
//                    print(testObject.property1)
//                    print(testObject.property2)
                }
            }
        } catch let error {
            print(error)
        }
    }

    func testFileLevelService() {
        let fileName = "DataFile.txt"

        guard let documentDirectory = try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true) else {
            return
        }

        let fileURL = documentDirectory.appendingPathComponent(fileName)

        do {
            let fileContent = "Text to encrypt"
            try fileContent.write(to: fileURL, atomically: false, encoding: .utf8)

            let contentBeforeEncryption = try String(contentsOf: fileURL, encoding: .utf8)
            print("File content before encryption: \(contentBeforeEncryption)")

            try FileLevelService.shared.encryptFile(at: fileURL)

            let contentAfterEncryption = try String(contentsOf: fileURL, encoding: .utf8)
            print("File content after encryption: \(contentAfterEncryption)")
        } catch let error {
            print("Error writing to file: \(error.localizedDescription)")
        }
    }
}

//
//  UserDefaultsActor.swift
//  ShiftScheduler
//
//  Created by Farley Caesar on 2025-10-23.
//


import Foundation

actor UserDefaultsActor {
    private let defaults: UserDefaults

    init(suiteName: String? = nil) {
        self.defaults = suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
    }

    // MARK: - Write
    
    func set<T>(_ value: T?, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    func removeValue(forKey key: String) {
        defaults.removeObject(forKey: key)
    }

    // MARK: - Read
    
    func string(forKey key: String) -> String? {
        defaults.string(forKey: key)
    }
    
    func bool(forKey key: String) -> Bool {
        defaults.bool(forKey: key)
    }

    func integer(forKey key: String) -> Int {
        defaults.integer(forKey: key)
    }

    func double(forKey key: String) -> Double {
        defaults.double(forKey: key)
    }

    func data(forKey key: String) -> Data? {
        defaults.data(forKey: key)
    }

    // MARK: - Codable support (optional)
    
    func setCodable<T: Codable>(_ value: T?, forKey key: String) throws {
        if let value = value {
            let data = try JSONEncoder().encode(value)
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
    
    func codable<T: Codable>(forKey key: String, as type: T.Type) throws -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
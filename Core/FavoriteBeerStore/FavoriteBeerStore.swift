// Copyright © 2019 Nazariy Gorpynyuk.
// All rights reserved.

import Foundation
import Cornerstones
import ReactiveSwift
import Result

// MARK: - Protocol

public protocol FavoriteBeerStoreProtocol {
    var beerIDs: [Int] { get }
    func addBeer(withID id: Int)
    func removeBeer(withID id: Int)
    var eventSignal: Signal<FavoriteBeerStore.Event, NoError> { get }
}

// MARK: - Implementation

// This would normally be implemented using Core Data or Realm.

public final class FavoriteBeerStore: FavoriteBeerStoreProtocol, SharedInstance, EventEmitter {

    public typealias InstanceProtocol = FavoriteBeerStoreProtocol
    public static var defaultInstance: InstanceProtocol = FavoriteBeerStore()

    public enum Event {
        case changed(beerIDs: [Int])
    }

    private static let storeKey = "favoriteBeers"

    private typealias `Self` = FavoriteBeerStore

    // MARK: - Lifecycle

    private init() {}

    // MARK: - Storage and access

    public var beerIDs: [Int] {
        return synchronized(self) {
            let favoriteBeers = (UserDefaults.standard.array(forKey: Self.storeKey) as? [Int]) ?? [Int]()
            return favoriteBeers
        }
    }

    public func addBeer(withID id: Int) {
        synchronized(self) {
            var favoriteBeers = (UserDefaults.standard.array(forKey: Self.storeKey) as? [Int]) ?? [Int]()
            var favoriteBeersSet = Set(favoriteBeers)
            let previousFavoriteBeersSet = favoriteBeersSet
            favoriteBeersSet.insert(id)
            favoriteBeers = Array(favoriteBeersSet)
            UserDefaults.standard.set(favoriteBeers, forKey: Self.storeKey)
            UserDefaults.standard.synchronize()

            if favoriteBeersSet != previousFavoriteBeersSet {
                eventEmitter.send(value: .changed(beerIDs: favoriteBeers))
            }
        }

        ActivityTracker.shared.userAddedBeerToFavorites()
    }

    public func removeBeer(withID id: Int) {
        synchronized(self) {
            var favoriteBeers = (UserDefaults.standard.array(forKey: Self.storeKey) as? [Int]) ?? [Int]()
            var favoriteBeersSet = Set(favoriteBeers)
            let previousFavoriteBeersSet = favoriteBeersSet
            favoriteBeersSet.remove(id)
            favoriteBeers = Array(favoriteBeersSet)
            UserDefaults.standard.set(favoriteBeers, forKey: Self.storeKey)
            UserDefaults.standard.synchronize()

            if favoriteBeersSet != previousFavoriteBeersSet {
                eventEmitter.send(value: .changed(beerIDs: favoriteBeers))
            }
        }
    }

}

//
//  KYBluetoothClient.swift
//  KYRxBluetooth
//
//  Created by admin on 17/3/29.
//

import Foundation
import CoreBluetooth
import RxSwift

public class KYBluetoothClient: NSObject {
    
    public let centralManager = KYCBCentralManager(queue: nil, options: nil)
    
    fileprivate let subscriKYionQueue = ConcurrentMainScheduler.instance
    fileprivate let lock = NSLock()
    fileprivate var scanPeripheral = [KYCBPeripheral]()
    
    public var state: KYBluetoothState {
        return KYBluetoothState(rawValue: centralManager.state.rawValue) ?? .unknown
    }
    
    public func stopScan() {
        centralManager.stopScan()
    }
    
    func ensureBluetoothState<T>(_ state: KYBluetoothState, observable: Observable<T>) -> Observable<T> {
        return self.state == state ? observable : .never()
    }
}
extension Reactive where Base: KYBluetoothClient {
    
    public func connect(_ peripheral: KYCBPeripheral, oKYions: [String: Any]? = nil) -> Observable<KYCBPeripheral> {
        
        let success = base.centralManager.rx.didConnectPeripheral
            .filter { $0 == peripheral }
            .take(1)
            .map { _ in return peripheral }
        
        let error = base.centralManager.rx.didFailConnectPeripheral
            .filter { $0.0 == peripheral }
            .take(1)
            .flatMap { (peripheral, error) -> Observable<KYCBPeripheral> in return .empty() }
        
        let observable = Observable<KYCBPeripheral>.create { (observer) -> Disposable in
            
            guard peripheral.isConnected == false else {
                observer.onNext(peripheral)
                observer.onCompleted()
                return Disposables.create()
            }
            
            let disposable = success.amb(error).subscribe(observer)
            
            self.base.centralManager.connect(peripheral, options: oKYions)
            
            return Disposables.create {
                if peripheral.isConnected == false {
                    self.base.centralManager.cancelPeripheralConnection(peripheral)
                    disposable.dispose()
                }
            }
        }
        
        return observable
    }
    
    public func scanForPeripherals() -> Observable<KYCBPeripheral> {
        
        base.scanPeripheral.removeAll()
        return .deferred {
            
            let observable = Observable.create { (element: AnyObserver<KYCBPeripheral>) -> Disposable in
                
                let didDiscover = self.base.centralManager.rx.didDiscoverPeripheral
                    .map { return $0 }
                    .subscribe(onNext: { (peripheral) in
                        
                        if self.base.scanPeripheral.contains(peripheral) == false {
                            self.base.scanPeripheral.append(peripheral)
                            element.onNext(peripheral)
                        }
                    })
                
                self.base.centralManager.scanForPeripherals(withServices: nil, options: nil)
                
                return Disposables.create {
                    didDiscover.dispose()
                    self.base.centralManager.stopScan()
                }
                }
                .subscribeOn(self.base.subscriKYionQueue)
                .publish()
                .refCount()
            
            return self.base.ensureBluetoothState(.poweredOn, observable: observable)
        }
    }
    
    public func cancelPeripheralConnection(_ peripheral: KYCBPeripheral) -> Observable<KYCBPeripheral> {
        
        return .deferred {
            
            let observable = Observable.create { (element: AnyObserver<KYCBPeripheral>) -> Disposable in
                
                let disposeable = self.base.centralManager.rx.didDisconnectPeripheralSubject
                    .map({ (peripheral, error) -> KYCBPeripheral in return peripheral })
                    .subscribe(element)
                
                self.base.centralManager.cancelPeripheralConnection(peripheral)
                
                return Disposables.create {
                    disposeable.dispose()
                }
                }
                .subscribeOn(self.base.subscriKYionQueue)
                .publish()
                .refCount()
            
            return self.base.ensureBluetoothState(.poweredOn, observable: observable)
        }
    }
    
    public var state: Observable<KYBluetoothState> {
        return .deferred {
            return self.base.centralManager.rx.didUpdateState.startWith(self.base.centralManager.state)
        }
    }
}

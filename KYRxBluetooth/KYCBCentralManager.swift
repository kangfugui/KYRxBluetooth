//
//  KYCBCentralManager.swift
//  KYRxBluetooth
//
//  Created by KangYang on 17/3/29.
//
//

import Foundation
import CoreBluetooth
import RxSwift

public class KYCBCentralManager: NSObject {
    
    public var centralManager: CBCentralManager!
    
    fileprivate let didUpdateStateSubject = PublishSubject<KYBluetoothState>()
    fileprivate let willRestoreStateSubject = PublishSubject<[String: Any]>()
    fileprivate let didDiscoverPeripheralSubject = PublishSubject<KYCBPeripheral>()
    fileprivate let didConnectPeripheralSubject = PublishSubject<KYCBPeripheral>()
    fileprivate let didFailConnectPeripheralSubject = PublishSubject<(KYCBPeripheral, Error?)>()
    fileprivate let didDisconnectPeripheralSubject = PublishSubject<(KYCBPeripheral, Error?)>()
    
    var state: KYBluetoothState {
        return KYBluetoothState(rawValue: centralManager.state.rawValue) ?? .unknown
    }
    
    convenience init(queue: DispatchQueue?, options: [String: Any]? = nil) {
        self.init()
        centralManager = CBCentralManager(delegate: self, queue: queue, options: options)
    }
    
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]? = nil) {
        return centralManager.scanForPeripherals(withServices: serviceUUIDs, options: options)
    }
    
    func connect(_ peripheral: KYCBPeripheral, options: [String : Any]? = nil) {
        centralManager.connect(peripheral.peripheral, options: options)
    }
    
    func cancelPeripheralConnection(_ peripheral: KYCBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral.peripheral)
    }
    
    func stopScan() {
        centralManager.stopScan()
    }
    
    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> Observable<[KYCBPeripheral]> {
        
        let result = centralManager.retrieveConnectedPeripherals(withServices: serviceUUIDs)
            .map { (peripheral) -> KYCBPeripheral in
                return KYCBPeripheral(peripheral: peripheral)
        }
        
        return .just(result)
    }
    
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> Observable<[KYCBPeripheral]> {
        
        let result = centralManager.retrievePeripherals(withIdentifiers: identifiers)
            .map { (peripheral) -> KYCBPeripheral in
                return KYCBPeripheral(peripheral: peripheral)
        }
        
        return .just(result)
    }
}

extension KYCBCentralManager: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if let bleState = KYBluetoothState(rawValue: central.state.rawValue) {
            didUpdateStateSubject.onNext(bleState)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        didDiscoverPeripheralSubject.onNext(KYCBPeripheral(peripheral: peripheral,
                                                           advertisementData: advertisementData,
                                                           RSSI: RSSI))
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        didConnectPeripheralSubject.onNext(KYCBPeripheral(peripheral: peripheral))
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        didDisconnectPeripheralSubject.onNext((KYCBPeripheral(peripheral: peripheral), error))
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        didFailConnectPeripheralSubject.onNext((KYCBPeripheral(peripheral: peripheral), error))
    }
    
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        willRestoreStateSubject.onNext(dict)
    }
}

extension Reactive where Base: KYCBCentralManager {
    
    var didUpdateState: Observable<KYBluetoothState> {
        return self.base.didUpdateStateSubject
    }
    
    var willRestoreState: Observable<[String: Any]> {
        return self.base.willRestoreStateSubject
    }
    
    var didDiscoverPeripheral: Observable<KYCBPeripheral> {
        return self.base.didDiscoverPeripheralSubject
    }
    
    var didConnectPeripheral: Observable<KYCBPeripheral> {
        return self.base.didConnectPeripheralSubject
    }
    
    var didFailConnectPeripheral: Observable<(KYCBPeripheral, Error?)> {
        return self.base.didFailConnectPeripheralSubject
    }
    
    var didDisconnectPeripheralSubject: Observable<(KYCBPeripheral, Error?)> {
        return self.base.didDisconnectPeripheralSubject
    }
}

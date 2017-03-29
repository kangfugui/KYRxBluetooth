//
//  KYCBPeripheral.swift
//  KYRxBluetooth
//
//  Created by admin on 17/3/29.
//

import Foundation
import CoreBluetooth
import RxSwift

public class KYCBPeripheral: NSObject {
    
    fileprivate let peripheralDidDiscoverServicesSubject = PublishSubject<CBService>()
    fileprivate let peripheralDidDiscoverCharacteristicsSubject = PublishSubject<[CBCharacteristic]>()
    fileprivate let peripheralDidUpdateValueSubject = PublishSubject<CBCharacteristic>()
    
    let peripheral: CBPeripheral
    var advertisementData: [String: Any]?
    var RSSI: NSNumber?
    
    public var state: CBPeripheralState {
        return peripheral.state
    }
    
    public var isConnected: Bool {
        return state == .connected
    }
    
    public var name: String? {
        return peripheral.name
    }
    
    public var identifier: UUID {
        return peripheral.identifier
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        if let rhs = object as? KYCBPeripheral {
            return peripheral == rhs.peripheral
        }
        return false
    }
    
    init(peripheral: CBPeripheral, advertisementData: [String: Any]? = nil, RSSI: NSNumber? = nil) {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.RSSI = RSSI
    }
    
    public func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic) {
        peripheral.setNotifyValue(enabled, for: characteristic)
    }
}

extension Reactive where Base: KYCBPeripheral {
    
    public func discoverServices(_ serviceUUIDs: [CBUUID]?) -> Observable<CBService> {
        base.peripheral.delegate = base
        self.base.peripheral.discoverServices(serviceUUIDs)
        return self.base.peripheralDidDiscoverServicesSubject
    }
    
    public func discoverCharacteristics(_ service: CBService, UUIDs: [CBUUID]? = nil) -> Observable<[CBCharacteristic]> {
        self.base.peripheral.discoverCharacteristics(UUIDs, for: service)
        return self.base.peripheralDidDiscoverCharacteristicsSubject
    }
}

extension KYCBPeripheral: CBPeripheralDelegate {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let services = peripheral.services ?? []
        services.forEach {
            peripheralDidDiscoverServicesSubject.onNext($0)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let characteristics = service.characteristics ?? []
        peripheralDidDiscoverCharacteristicsSubject.onNext(characteristics)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        peripheralDidUpdateValueSubject.onNext(characteristic)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.isNotifying && characteristic.properties == .read {
            peripheral.readValue(for: characteristic)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
    }
}

public func == (lhs: KYCBPeripheral, rhs: KYCBPeripheral) -> Bool {
    return lhs.peripheral == rhs.peripheral
}

##### 推荐阅读
* [Getting Started With RxSwift and RxCocoa](http://southpeak.github.io/2017/01/16/Getting-Started-With-RxSwift-and-RxCocoa/)
* [RxSwift 入坑手册 Part1 - 示例实战](https://blog.callmewhy.com/2015/09/23/rxswift-getting-started-1/)
* [Why use rx](https://github.com/ReactiveX/RxSwift/blob/master/Documentation/Why.md)

##### 如何使用

```
client.rx.state  //监听手机蓝牙状态
.flatMap { (state) -> Observable<PTCBPeripheral> in
    return state == .poweredOn ? self.client.rx.scanForPeripherals() : .never() //开启蓝牙后搜寻周围设备
}
.timeout(30.0, scheduler: MainScheduler.instance) //30秒超时
.subscribeOn(MainScheduler.instance) //回到主线程
.flatMap { (peripheral) -> Observable<PTCBPeripheral> in
    if peripheral.name == "PaiBand-E13A473488A5" {
        self.client.stopScan()
        self.aPeripheral = peripheral
        return self.client.rx.connect(peripheral) //找到设备后尝试连接，并停止搜寻
    } else {
        return Observable.never()
    }
}
.flatMap { $0.rx.discoverServices(nil) } //连上设备后搜寻Services
.flatMap { (service) -> Observable<[CBCharacteristic]> in
    if service.uuid.uuidString == "6E400001-B5A3-F393-E0A9-E50E24DCCA9E" {
    return self.aPeripheral?.rx.discoverCharacteristics(service) ?? .never()
    //找到指定Service后搜寻Characteristics
    } else {
        return .never()
    }
}.subscribe(onNext: { (characteristics) in

    characteristics.forEach {
        let properties = UInt8($0.properties.rawValue)
        let writeWithoutResponse = UInt8(CBCharacteristicProperties.writeWithoutResponse.rawValue)
        
        if properties & writeWithoutResponse > 0 {
            self.writeCharacteristic = $0
        } else if $0.properties == .notify {
            self.aPeripheral?.setNotifyValue(true, for: $0)
        }
    }

    //判断Characteristics类型，开启notify
            
}).addDisposableTo(_disposeBag)

```
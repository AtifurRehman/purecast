// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:purecast/src/utils/constants.dart';

import './mdns/multicast_dns.dart';
import 'cast_device/cast_device.dart';
import 'mdns/resource_record.dart';

class PureCast {
  static const String gcastName = '_googlecast._tcp.local';
  PureCast() {}
  final MDnsClient client = MDnsClient(rawDatagramSocketFactory:
      (dynamic host, int port,
          {bool reuseAddress = CastConstants.reuseAddress,
          bool reusePort = CastConstants.reusePort,
          int ttl = CastConstants.hostTTL}) {
    print(
        "RawDatagramSocket.bind($host, $port, reuseAddress: $reuseAddress, reusePort: $reusePort, ttl: $ttl)");
    return RawDatagramSocket.bind(host, port,
            reuseAddress: reuseAddress, reusePort: reusePort, ttl: ttl)
        .then((value) {
      print("RawDatagramSocket: ${value.toString()}");
      value.handleError((error) {
        print("RawDatagramSocket error: $error");
      });
      return value;
    });
  });
  Stream<PtrResourceRecord> get _ptrStream => client.lookup<PtrResourceRecord>(
      ResourceRecordQuery.serverPointer(gcastName),
      timeout: const Duration(seconds: 10));
  Stream<SrvResourceRecord> _srvStream(PtrResourceRecord ptr) =>
      client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
          timeout: const Duration(seconds: 10));
  Stream<IPAddressResourceRecord> _ipStream(SrvResourceRecord srv) =>
      client.lookup<IPAddressResourceRecord>(
          ResourceRecordQuery.addressIPv4(srv.target),
          timeout: const Duration(seconds: 10));
  Future<void> get _startClient => client.start(
      listenAddress: InternetAddress.anyIPv4,
      interfacesFactory: (InternetAddressType type) {
        return NetworkInterface.list(
          includeLinkLocal: true,
          type: type,
          includeLoopback: false,
        ).then((value) {
          print(value.fold(
              "Interfaces: ",
              (e, f) =>
                  "$e ${f.addresses.fold("", (previousValue, element) => "$previousValue ${element.toString()}")}"));
          return value;
        });
      });
  StreamController<CastDevice> scanForDevices() {
    StreamController<CastDevice> castDeviceStreamController =
        StreamController.broadcast(onCancel: () => client.stop());
    castDeviceStreamController.onListen =
        () => _onListen(castDeviceStreamController);
    return castDeviceStreamController;
  }

  Future<void> _onListen(StreamController<CastDevice> streamController) async {
    print('Starting mDNS client');
    await _startClient;
    print('mDNS client started');
    Stream<PtrResourceRecord> ptrStream = _ptrStream;
    late StreamSubscription ptrSub;
    Map<String, PtrResourceRecord> ptrMap = {};
    ptrSub = ptrStream.listen((event) {
      print('PTR: ${event.toString()}');
      ptrMap[event.domainName] = event;
    });
    // To match the 10 second timeout in the PTR query
    int ticks = 100;
    while (ptrMap.isEmpty || ticks > 10) {
      ticks--;
      await Future.delayed(Duration(milliseconds: 100));
      ticks % 10 == 0 ? print('Waiting for PTR') : null;
      if (ticks == 0 && ptrMap.isEmpty) {
        print('PTR timeout, restarting PTR stream');
        ticks = 100;
        ptrSub.cancel();
        client.stop();
        await _startClient;
        ptrStream = _ptrStream;
        ptrSub = ptrStream.listen((event) {
          print('PTR: ${event.toString()}');
          ptrMap[event.domainName] = event;
        });
      }
    }
    ptrSub.cancel();
    print(
        'PTRs: ${ptrMap.values.fold("", (previousValue, element) => "$previousValue, ${element.toString()}").toString()}');
    // This poor guy gets tired : ( we need to give him a break
    client.stop();
    await Future.delayed(Duration(milliseconds: 50));
    print('Starting mDNS client');
    await _startClient;
    print('mDNS client started');
    Map<PtrResourceRecord, SrvResourceRecord> srvMap = {};
    for (PtrResourceRecord ptr in ptrMap.values) {
      print('Getting SRV for PTR: ${ptr.toString()}');
      SrvResourceRecord? srv;
      Stream<SrvResourceRecord> srvStream = _srvStream(ptr);
      late StreamSubscription srvSub;
      srvSub = srvStream.listen((event) {
        print('SRV: ${event.toString()}');
        srv = event;
        srvSub.cancel();
      });
      int ticks = 100;
      while (srv == null) {
        ticks--;
        await Future.delayed(Duration(milliseconds: 100));
        ticks % 10 == 0 ? print('Waiting for SRV') : null;
        if (ticks == 0) {
          print('SRV timeout, restarting SRV stream');
          ticks = 100;
          srvSub.cancel();
          srvStream = _srvStream(ptr);
          srvSub = srvStream.listen((event) {
            print('SRV: ${event.toString()}');
            srv = event;
            srvSub.cancel();
          });
        }
      }
      srvSub.cancel();
      print('SRV: ${srv.toString()}');
      srvMap[ptr] = srv!;
    }
    // Sleepy again
    client.stop();
    await Future.delayed(Duration(milliseconds: 50));
    print('Starting mDNS client');
    await _startClient;
    print('mDNS client started');
    for (MapEntry<PtrResourceRecord, SrvResourceRecord> ptrSrvPair
        in srvMap.entries) {
      print('Getting IP for SRV: ${ptrSrvPair.value.toString()}');
      IPAddressResourceRecord? ip;
      Stream<IPAddressResourceRecord> ipStream = _ipStream(ptrSrvPair.value);
      late StreamSubscription ipSub;
      ipSub = ipStream.listen((event) {
        print('IP: ${event.toString()}');
        ip = event;
        ipSub.cancel();
      });
      int ticks = 100;
      while (ip == null) {
        ticks--;
        await Future.delayed(Duration(milliseconds: 100));
        ticks % 10 == 0 ? print('Waiting for IP') : null;
        if (ticks == 0) {
          print('IP timeout, restarting IP stream');
          ticks = 100;
          ipSub.cancel();
          ipStream = _ipStream(ptrSrvPair.value);
          ipSub = ipStream.listen((event) {
            print('IP: ${event.toString()}');
            ip = event;
            ipSub.cancel();
          });
        }
      }
      ipSub.cancel();
      CastDevice.create(
              defaultName: ptrSrvPair.key.name,
              host: ip!.address.address,
              port: ptrSrvPair.value.port)
          .then((device) => streamController.add(device));
    }
    client.stop();
  }
}

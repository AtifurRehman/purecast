// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:universal_io/io.dart';

import 'package:purecast/src/utils/constants.dart';

import './mdns/multicast_dns.dart';
import 'cast_device/cast_device.dart';
import 'mdns/resource_record.dart';

class PureCast {
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

  Duration get _defaultTimeout => const Duration(seconds: 10);

  Stream<PtrResourceRecord> _ptrStream() => client.lookup<PtrResourceRecord>(
      ResourceRecordQuery.serverPointer(CastConstants.gcastName),
      timeout: _defaultTimeout);
  Stream<SrvResourceRecord> _srvStream(PtrResourceRecord ptr) =>
      client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
          timeout: _defaultTimeout);
  Stream<IPAddressResourceRecord> _ipStream(SrvResourceRecord srv) =>
      client.lookup<IPAddressResourceRecord>(
          ResourceRecordQuery.addressIPv4(srv.target),
          timeout: _defaultTimeout);
  Future<void> _startClient() => client.start(
      listenAddress: InternetAddress.anyIPv4,
      interfacesFactory: (InternetAddressType type) => NetworkInterface.list(
            includeLinkLocal: true,
            type: type,
            includeLoopback: false,
          ).then((value) {
            print(value.fold(
                "Interfaces: ",
                (e, f) =>
                    "$e ${f.addresses.fold("", (previousValue, element) => "$previousValue ${element.toString()}")}"));
            return value;
          }));

  StreamController<CastDevice> scanForDevices() {
    StreamController<CastDevice> castDeviceStreamController =
        StreamController.broadcast(onCancel: () => client.stop());
    castDeviceStreamController.onListen =
        () => _onListen(castDeviceStreamController);
    return castDeviceStreamController;
  }

  Future<void> _onListen(StreamController<CastDevice> streamController) async {
    await restartClient('Starting mDNS client');

    // Listen to PTR records and wait for an event
    PtrResourceRecord ptr =
        await listenToStream<PtrResourceRecord>(() => _ptrStream(), 'PTR');

    // Restart client and listen to SRV records
    // await restartClient('Refreshing mDNS client');
    SrvResourceRecord srv =
        await listenToStream<SrvResourceRecord>(() => _srvStream(ptr), 'SRV');
    // Restart client and resolve IPs for SRV records
    // await restartClient('Refreshing mDNS client');
    var ip = await listenToStream(() => _ipStream(srv), 'IP');
    CastDevice.create(
            defaultName: ptr.name, host: ip.address.address, port: srv.port)
        .then((CastDevice device) {
      streamController.add(device);
    });
  }

  Future<void> restartClient(String message) async {
    client.stop();
    await Future.delayed(Duration(milliseconds: CastConstants.mdnsDelay));
    print(message);
    await _startClient();
    print('mDNS client started');
  }

  Future<T> listenToStream<T>(
      Stream<T> Function() getStream, String logPrefix) async {
    T? result;
    StreamSubscription? sub;
    int ticks = CastConstants.maxTicks;

    void onData(T event) {
      print('$logPrefix: ${event.toString()}');
      result = event;
      sub?.cancel();
    }

    sub = getStream().listen(onData);
    while (result == null && ticks > 0) {
      await Future.delayed(Duration(milliseconds: CastConstants.mdnsDelay));
      if (--ticks % 10 == 0) print('Waiting for $logPrefix');
    }

    sub.cancel();

    if (result == null) {
      print('$logPrefix timeout, restarting stream');
      return listenToStream(getStream, logPrefix);
    }

    return result!;
  }
}

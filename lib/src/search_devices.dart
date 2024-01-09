// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Example script to illustrate how to use the mdns package to discover the port
// of a Dart observatory over mDNS.

import 'package:multicast_dns/multicast_dns.dart';
import 'package:purecast/purecast.dart';

class PureCast {
  PureCast._() {}
  static Future<List<CastDevice>> searchDevices() async {
    const String name = '_googlecast._tcp.local';
    final MDnsClient client = MDnsClient();
    Set<Map> services = {};
    // Start the client with default options.
    await client.start();
    // Get the PTR recod for the service.
    await for (PtrResourceRecord ptr in client
        .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(name))) {
      // Use the domainName from the PTR record to get the SRV record,
      // which will have the port and local hostname.
      // Note that duplicate messages may come through, especially if any
      // other mDNS queries are running elsewhere on the machine.
      await for (SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName))) {
        await for (IPAddressResourceRecord ip
            in client.lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv4(srv.target))) {
          services.add({
            'name': srv.name,
            'port': srv.port,
            'ip': ip.address.address,
          });
        }
      }
    }
    client.stop();
    return Future.wait([
      for (Map service in services)
        CastDevice.create(
          defaultName: service['name'],
          host: service['ip'],
          port: service['port'],
        )
    ]);
  }
}

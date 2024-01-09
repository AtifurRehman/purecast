import 'package:multicast_dns/multicast_dns.dart';
import 'package:purecast/purecast.dart';

class PureCast {
  PureCast._() {}
  static Future<List<CastDevice>> searchDevices() async {
    const String name = '_googlecast._tcp.local';
    final MDnsClient client = MDnsClient();
    List<Future<CastDevice>> futures = [];
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
          futures.add(CastDevice.create(
            defaultName: srv.name,
            host: ip.address.address,
            port: srv.port,
          ));
        }
      }
    }
    client.stop();
    return Future.wait(futures);
  }
}

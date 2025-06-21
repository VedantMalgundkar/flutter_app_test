import 'package:multicast_dns/multicast_dns.dart';

class HyperhdrDiscoveryService {
  Future<List<Map<String, dynamic>>> discover() async {
    final mdns = MDnsClient();
    final List<Map<String, dynamic>> servers = [];

    await mdns.start();

    await for (final ptr in mdns.lookup<PtrResourceRecord>(
      ResourceRecordQuery.serverPointer('_hyperhdr._tcp.local'),
    )) {
      await for (final srv in mdns.lookup<SrvResourceRecord>(
        ResourceRecordQuery.service(ptr.domainName),
      )) {
        await for (final ip in mdns.lookup<IPAddressResourceRecord>(
          ResourceRecordQuery.addressIPv4(srv.target),
        )) {
          final uri = Uri.parse("http://${ip.address.address}:${srv.port}");
          print("🔍 Found PTR: ${ptr.domainName}");
          print("🔍 Found SRV: ${srv.target}:${srv.port}");
          print("🔍 Found IP: ${ip.address.address}");
          servers.add({"label": srv.target, "url": uri});
        }
      }
    }

    mdns.stop();
    return servers;
  }
}

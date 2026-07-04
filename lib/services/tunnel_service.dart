import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

class TunnelService {
  HttpServer? _httpServer;
  SSHClient? _sshClient;
  String? publicUrl;
  
  // Hàm callback khi nhận được cấu hình
  Future<void> Function(Map<String, dynamic>)? onConfigReceived;

  Future<String?> startTunnel() async {
    try {
      // 1. Khởi tạo Local Server
      final handler = const Pipeline().addHandler(_handleRequest);
      _httpServer = await shelf_io.serve(handler, InternetAddress.loopbackIPv4, 0);
      final localPort = _httpServer!.port;
      print('TunnelService: Local server running on port $localPort');

      // 2. Mở SSH Tunnel tới localhost.run
      print('TunnelService: Bắt đầu kết nối SSH tới localhost.run...');
      final socket = await SSHSocket.connect('localhost.run', 22, timeout: const Duration(seconds: 10));
      print('TunnelService: Đã mở socket, đang khởi tạo SSH Client...');
      
      _sshClient = SSHClient(
        socket, 
        username: 'nokey',
        onPasswordRequest: () => '',
      );
      
      final completer = Completer<String?>();

      // Khởi tạo shell session để đọc public URL từ stdout của localhost.run
      final session = await _sshClient!.shell();
      session.stdout.cast<List<int>>().transform(utf8.decoder).listen((data) {
        print('TunnelService SSH Output: $data');
        // Tìm URL tunnel trong stdout
        final regExp = RegExp(r'https://[a-zA-Z0-9.-]+\.(lhr\.life|lhr\.pro|localhost\.run)');
        final match = regExp.firstMatch(data);
        if (match != null && !completer.isCompleted) {
          publicUrl = match.group(0);
          print('TunnelService: Tìm thấy Public URL: $publicUrl');
          completer.complete(publicUrl);
        }
      });

      // Gửi yêu cầu remote port forwarding (nhận kết nối từ cổng 80 của localhost.run)
      print('TunnelService: Đang yêu cầu forwardRemote port 80...');
      final forward = await _sshClient!.forwardRemote(port: 80);
      
      if (forward != null) {
        forward.connections.listen((connection) async {
          try {
            print('TunnelService: Nhận kết nối mới từ tunnel, đang chuyển tiếp tới local port $localPort...');
            final localSocket = await Socket.connect('127.0.0.1', localPort);
            
            // Chuyển tiếp dữ liệu hai chiều
            connection.stream.listen(
              (data) {
                localSocket.add(data);
              },
              onError: (e) {
                print('TunnelService connection error on remote channel: $e');
                localSocket.destroy();
              },
              onDone: () {
                localSocket.destroy();
              },
            );
            
            localSocket.listen(
              (data) {
                connection.sink.add(data);
              },
              onError: (e) {
                print('TunnelService connection error on local socket: $e');
                connection.close();
              },
              onDone: () {
                connection.close();
              },
            );
          } catch (e) {
            print('TunnelService: Không thể kết nối tới local port: $e');
            connection.close();
          }
        });
      }

      // Timeout sau 15 giây nếu không lấy được URL
      Future.delayed(const Duration(seconds: 15), () {
        if (!completer.isCompleted) {
          print('TunnelService: Khởi tạo tunnel bị timeout.');
          completer.complete(null);
        }
      });

      return completer.future;
    } catch (e) {
      print('TunnelService error: $e');
      stopTunnel();
      return null;
    }
  }

  Future<Response> _handleRequest(Request request) async {
    // CORS Headers
    final corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
    };

    if (request.method == 'OPTIONS') {
      return Response.ok('', headers: corsHeaders);
    }

    if (request.method == 'POST' && request.url.path == 'config') {
      try {
        final body = await request.readAsString();
        final data = json.decode(body) as Map<String, dynamic>;
        
        print('TunnelService: Nhận được config qua tunnel.');
        if (onConfigReceived != null) {
          await onConfigReceived!(data);
        }
        
        return Response.ok(
          json.encode({'success': true, 'message': 'Config applied successfully!'}),
          headers: {...corsHeaders, 'content-type': 'application/json'},
        );
      } catch (e) {
        print('TunnelService: Lỗi xử lý config: $e');
        return Response.internalServerError(
          body: 'Error processing config: $e',
          headers: corsHeaders,
        );
      }
    }
    return Response.notFound('Not Found', headers: corsHeaders);
  }

  void stopTunnel() {
    print('TunnelService: Đang dừng HTTP Server và SSH Tunnel...');
    _httpServer?.close(force: true);
    _httpServer = null;
    _sshClient?.close();
    _sshClient = null;
    publicUrl = null;
  }
}

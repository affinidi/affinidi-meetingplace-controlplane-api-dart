import 'package:shelf/shelf.dart';

String getAuthDid(Request request) => request.context['authDid'].toString();

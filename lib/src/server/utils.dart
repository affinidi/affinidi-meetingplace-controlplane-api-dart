import 'package:shelf/shelf.dart';

String getAuthDid(Request request) => request.context['authDid'].toString();

String getAuthVerificationMethod(Request request) =>
    request.context['authVerificationMethod'].toString();

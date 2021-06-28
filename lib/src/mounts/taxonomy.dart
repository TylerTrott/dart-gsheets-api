import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class Taxonomy {
  Router get router {
    final router = Router();

    router.all('/<.*>', (req) => Response.notFound('Not Found'));

    return router;
  }
}
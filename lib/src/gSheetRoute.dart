import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:gsheets/gsheets.dart' show Spreadsheet, Worksheet;
import 'package:dart_gsheets_api/src/gSheetDriver.dart';

class GSheetRoute {
  final GSheetDriver _gSheetDriver = GSheetDriver.getInstance();

  final String _spreadsheetId;
  final int _firstDataRow;
  final List<String> _worksheets;

  Spreadsheet? _spreadsheet;
  DateTime lastUpdate = DateTime.now();

  GSheetRoute(this._spreadsheetId, this._firstDataRow, this._worksheets);

  bool _shouldRefresh() =>
      _spreadsheet == null || lastUpdate.difference(DateTime.now()).inHours > 0;

  Future<void> _refresh() async {
    _spreadsheet = await _gSheetDriver.getSpreadsheet(_spreadsheetId);
  }

  Worksheet _worksheet(id) => _spreadsheet!.worksheetById(id)!;

  Router _mountRouter(String worksheetId) {
    final router = Router();

    router.get('/column/<column|[0-9]+>', (req, String column) async {
      try {
        if (_shouldRefresh()) await _refresh();
        var data = await _worksheet(worksheetId)
            .values
            .column(int.parse(column), fromRow: _firstDataRow);
        return Response.ok(jsonEncode(data),
            headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response.internalServerError();
      }
    });

    router.get('/row/<row|[0-9]+>', (req, String row) async {
      try {
        if (_shouldRefresh()) await _refresh();
        var data = await _worksheet(worksheetId)
            .values
            .row(int.parse(row));
        return Response.ok(jsonEncode(data),
            headers: {'content-type': 'application/json'});
      } catch (e) {
        return Response.internalServerError();
      }
    });

    return router;
  }

  Router get router {
    final router = Router();
    router.get('/refresh', (req) async {
      try {
        await _refresh();
        return Response.ok('Refreshed sheet');
      } catch (e) {
        return Response.internalServerError();
      }
    });

    _worksheets.forEach(
        (worksheetId) => router.mount('/$worksheetId', _mountRouter(worksheetId)));

    return router;
  }
}
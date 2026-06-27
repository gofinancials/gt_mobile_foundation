import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

void main() {
  group('ApiResponse Tests', () {
    test('Constructor should initialize with default and provided values', () {
      const defaultResponse = ApiResponse();
      expect(defaultResponse.responseCode, '200');
      expect(defaultResponse.message, isNull);
      expect(defaultResponse.data, isNull);

      const customResponse = ApiResponse(
        responseCode: '404',
        message: 'Not Found',
        data: {'id': 1},
      );
      expect(customResponse.responseCode, '404');
      expect(customResponse.message, 'Not Found');
      expect(customResponse.data, equals({'id': 1}));
    });

    test('copyWith should update specified fields and retain others', () {
      const original = ApiResponse(
        responseCode: '200',
        message: 'Success',
        data: 'Data',
      );

      final updatedCode = original.copyWith(responseCode: '500');
      expect(updatedCode.responseCode, '500');
      expect(updatedCode.message, 'Success');
      expect(updatedCode.data, 'Data');

      final updatedMessage = original.copyWith(message: 'Failed');
      expect(updatedMessage.responseCode, '200');
      expect(updatedMessage.message, 'Failed');
      expect(updatedMessage.data, 'Data');

      final updatedData = original.copyWith(data: {'new': 'data'});
      expect(updatedData.responseCode, '200');
      expect(updatedData.message, 'Success');
      expect(updatedData.data, equals({'new': 'data'}));
    });

    group('fromJson', () {
      test('should parse exact keys if available', () {
        final json = {
          'responseCode': '201',
          'message': 'Created',
          'data': {'id': 2},
        };
        final response = ApiResponse.fromJson(json);

        expect(response.responseCode, '201');
        expect(response.message, 'Created');
        expect(response.data, equals({'id': 2}));
      });

      test('should fallback to defaults if keys are missing', () {
        final json = {'randomKey': 'value'};
        final response = ApiResponse.fromJson(
          json,
          defaultCode: '400',
          defaultMessage: 'Bad Request',
        );

        expect(response.responseCode, '400');
        expect(response.message, 'Bad Request');
        expect(response.data, equals(json)); // Fallback is the entire json
      });

      test(
        'should fallback to "200" if no defaultCode is provided and responseCode is missing',
        () {
          final json = {'randomKey': 'value'};
          final response = ApiResponse.fromJson(json);

          expect(response.responseCode, '200');
          expect(response.message, isNull);
          expect(response.data, equals(json));
        },
      );
    });

    group('fromResponse', () {
      test('should parse correctly from a Dio Response with Map data', () {
        final dioResponse = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 404,
          statusMessage: 'Not Found HTTP',
          data: {
            'responseCode': '404-API',
            'message': 'Not Found API',
            'data': {'error': 'true'},
          },
        );

        final response = dioResponse.asApiResponse;

        // API json fields should override the HTTP defaults
        expect(response.responseCode, '404-API');
        expect(response.message, 'Not Found API');
        expect(response.data, equals({'error': 'true'}));
      });

      test('should fallback to HTTP status when Map data lacks fields', () {
        final dioResponse = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
          statusMessage: 'Internal Server Error',
          data: {'internal': 'error'},
        );

        final response = dioResponse.asApiResponse;

        expect(response.responseCode, '500'); // Fallback from HTTP
        expect(response.message, 'Internal Server Error'); // Fallback from HTTP
        expect(response.data, equals({'internal': 'error'}));
      });

      test('should parse correctly from a Dio Response with non-Map data', () {
        final dioResponse = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 200,
          statusMessage: 'OK',
          data: 'Success String',
        );

        final response = dioResponse.asApiResponse;

        expect(response.responseCode, '200');
        expect(response.message, 'OK');
        expect(response.data, 'Success String');
      });
    });

    test('Equatable props should determine equality correctly', () {
      const response1 = ApiResponse(
        responseCode: '200',
        message: 'OK',
        data: 'A',
      );
      const response2 = ApiResponse(
        responseCode: '200',
        message: 'OK',
        data: 'A',
      );
      const response3 = ApiResponse(
        responseCode: '400',
        message: 'Bad',
        data: 'B',
      );

      expect(response1, equals(response2));
      expect(response1, isNot(equals(response3)));
    });
  });
}

import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// Reads the envelope a gateway reply carries, whichever layer carries it.
///
/// A reply arrives in two layers. [DioResponse.data] is the payload the crypto
/// interceptor unwrapped; `rawResponse.data` still carries the outer `data`
/// wrapper. Reading the outer layer hides the success flag one level down and
/// reports every success as a failure — which is what happens when this is
/// written per module and one copy reverses the order.
class ApiEnvelope {
  const ApiEnvelope._();

  /// The status keys that live on the outer wrapper of a plaintext response.
  static const statusKeys = [
    ...AppJson.successKeys,
    'responseCode',
    'ResponseCode',
    ...AppJson.messageKeys,
  ];

  /// The envelope [response] carries.
  ///
  /// An encrypted call's single unwrap lands on the decrypted inner envelope,
  /// which carries the flag itself. A plaintext call's unwrap consumes the only
  /// envelope there is, so the wrapper's status keys are lifted back onto the
  /// payload — its `data` never is, so a still-wrapped body cannot shadow the
  /// payload.
  static Map<String, dynamic> of(DioResponse response) {
    final raw = AppJson.asMap(response.rawResponse?.data);

    // A bare collection carries no status of its own, so it is nested under
    // the wrapper's status: otherwise a reported failure renders as an empty
    // list.
    if (response.data case List items) {
      return {..._status(raw), 'data': items};
    }

    final data = AppJson.asMap(response.data);
    if (AppJson.successFlag(data) != null) return data;

    final payload = data.isEmpty ? AppJson.payload(raw) : data;
    if (AppJson.successFlag(payload) != null) return payload;

    return {..._status(raw), ...payload};
  }

  /// Whether [envelope] reports that the gateway completed the operation.
  ///
  /// Absence and rejection are different answers. A mutation sets
  /// [requireSuccessFlag] so a missing flag fails closed; a read leaves it off,
  /// because for a read the payload is itself the evidence and not every read
  /// contract carries a flag.
  static bool accepts(
    Map<String, dynamic> envelope, {
    required bool requireSuccessFlag,
  }) {
    final flag = AppJson.successFlag(envelope);
    return flag != false && !(flag == null && requireSuccessFlag);
  }

  /// The gateway's own message for a refused [envelope], or the generic one.
  static String refusalMessage(Map<String, dynamic> envelope) {
    final message = AppJson.message(envelope);
    if (message.hasValue) return message;
    return locator<AppConfig>().strings.requestRefused.tr();
  }

  /// The wrapper's status keys, never its `data`.
  static Map<String, dynamic> _status(Map<String, dynamic> raw) => {
    for (final key in statusKeys)
      if (raw.containsKey(key)) key: raw[key],
  };
}

/// {@category Mixins}
/// Sends a gateway request and decodes the envelope it answers with.
extension ApiEnvelopeRequest on AppHttpMixin {
  /// Sends [send] and decodes its envelope, treating a reported refusal as a
  /// failure rather than a payload.
  ///
  /// The gateway answers `200` while reporting a refusal in the body, so an
  /// envelope whose success flag is false becomes a [TaskFailure] carrying the
  /// gateway's own message. A mutation keeps [requireSuccessFlag] on, so a
  /// missing flag also fails; a read turns it off, because its payload is the
  /// evidence.
  TaskCallResponse<T> sendEnvelope<T>(
    FutureCall<DioResponse> send,
    MapCallback<T, Map<String, dynamic>> decode, {
    bool requireSuccessFlag = true,
  }) async {
    final response = await requestHandler(
      () async => ApiEnvelope.of(await send()),
    );
    return switch (response) {
      TaskFailure(:final error) => TaskFailure(error: error),
      TaskSuccess(:final data)
          when !ApiEnvelope.accepts(
            data,
            requireSuccessFlag: requireSuccessFlag,
          ) =>
        TaskFailure(
          error: TaskError(message: ApiEnvelope.refusalMessage(data)),
        ),
      TaskSuccess(:final data) => TaskSuccess(data: decode(data)),
    };
  }
}

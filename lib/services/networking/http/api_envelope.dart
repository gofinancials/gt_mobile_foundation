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

  /// The keys a gateway spells its business code with.
  static const codeKeys = ['responseCode', 'ResponseCode'];

  /// The status keys that live on the outer wrapper of a plaintext response.
  static const statusKeys = [
    ...AppJson.successKeys,
    ...codeKeys,
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

  /// Whether [response] arrived with no body at all.
  ///
  /// Dio hands a `204 No Content` over as `null` under a JSON content type and
  /// as empty text without one. A body that was sent, even `{}`, is an
  /// envelope and is read as one.
  static bool isBodiless(DioResponse response) =>
      _isBlank(response.data) && _isBlank(response.rawResponse?.data);

  /// The gateway's own message for a refused [envelope], or the generic one.
  static String refusalMessage(Map<String, dynamic> envelope) {
    final message = AppJson.message(envelope);
    if (message.hasValue) return message;
    return locator<AppConfig>().strings.requestRefused.tr();
  }

  /// The business code the gateway put in [envelope], trimmed, or empty when
  /// it put none.
  ///
  /// Kept as the gateway spelled it, so a `"00"` stays `"00"`.
  static String code(Map<String, dynamic> envelope) =>
      AppJson.stringAt(envelope, codeKeys);

  static bool _isBlank(Object? body) => switch (body) {
    null => true,
    String text => !text.hasValue,
    _ => false,
  };

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
  ///
  /// That refusal is stamped with the envelope's business code, falling back
  /// to the HTTP status only when the envelope carries none, so a caller can
  /// tell one refusal from another by [TaskError.statusCode]. A [decode]
  /// failure keeps the HTTP status: its envelope was accepted, and its code
  /// says so.
  ///
  /// A `2xx` that arrives with no body is accepted whatever
  /// [requireSuccessFlag] says: the status is the gateway's whole answer, and
  /// there is no body to report a refusal in. [decode] then receives an empty
  /// map, and making sense of that is the caller's job.
  ///
  /// Both of the caller's own steps are guarded, so a failure in either
  /// arrives as a [TaskFailure] rather than a rejected future: [send] by
  /// [requestHandler], and [decode] — which runs after the reply is accepted —
  /// by [decodeHandler]. [decode] stays after the acceptance check, so an
  /// envelope the gateway refused is never decoded and a refusal keeps the
  /// gateway's message instead of a decoder's failure.
  ///
  /// What sits between them is this library's own and is not guarded: the
  /// acceptance check cannot throw, and the refusal message throws only with
  /// no [AppConfig] registered, which the guards themselves need too.
  TaskCallResponse<T> sendEnvelope<T>(
    FutureCall<DioResponse> send,
    MapCallback<T, Map<String, dynamic>> decode, {
    bool requireSuccessFlag = true,
  }) async {
    // The reply travels alongside its envelope because the status belongs to
    // the reply and the envelope no longer carries it.
    final response = await requestHandler(() async {
      final reply = await send();
      return (reply, ApiEnvelope.of(reply));
    });

    return switch (response) {
      TaskFailure(:final error) => TaskFailure(error: error),
      TaskSuccess(data: (final reply, final envelope))
          when !_isAccepted(reply, envelope, requireSuccessFlag) =>
        TaskFailure(
          error: TaskError(
            message: ApiEnvelope.refusalMessage(envelope),
            statusCode: _refusalCodeOf(reply, envelope),
          ),
        ),
      TaskSuccess(data: (final reply, final envelope)) => await decodeHandler(
        () async => decode(envelope),
        statusCode: _statusOf(reply),
      ),
    };
  }

  /// Whether the gateway completed the operation [reply] answers.
  bool _isAccepted(
    DioResponse reply,
    Map<String, dynamic> envelope,
    bool requireSuccessFlag,
  ) {
    if (ApiEnvelope.isBodiless(reply) && _isSuccessStatus(reply)) return true;
    return ApiEnvelope.accepts(
      envelope,
      requireSuccessFlag: requireSuccessFlag,
    );
  }

  bool _isSuccessStatus(DioResponse reply) {
    final status = _statusCodeOf(reply);
    return status >= 200 && status < 300;
  }

  /// The code a refusal of [envelope] is stamped with: the gateway's business
  /// code, or the HTTP status [reply] arrived with when it sent none.
  ///
  /// This is the order [AppHelpers.parseError] reads a thrown `4xx` in, so one
  /// refusal carries the same code whichever status it arrives with. It is
  /// read from the envelope, never [DioResponse.responseCode]: on an encrypted
  /// reply that is the outer wrapper's code, not the one the gateway refused
  /// with. Unlike [AppHelpers.parseError], which reads the code as an integer,
  /// the code is kept as spelled, so a `"00"` is not stamped `"0"`.
  String _refusalCodeOf(DioResponse reply, Map<String, dynamic> envelope) {
    final code = ApiEnvelope.code(envelope);
    if (code.hasValue) return code;
    return _statusOf(reply);
  }

  /// The HTTP status [reply] arrived with, never the business code the gateway
  /// nested in its body.
  ///
  /// A reply that reached here arrived, so `200` is the reading when the
  /// transport did not state one.
  String _statusOf(DioResponse reply) => "${_statusCodeOf(reply)}";

  int _statusCodeOf(DioResponse reply) => reply.rawResponse?.statusCode ?? 200;
}

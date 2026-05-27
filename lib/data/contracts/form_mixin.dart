import 'package:flutter/material.dart';

/// {@category Data}
/// A contract for form management mixins.
///
/// ### Example Usage
///
/// ```dart
/// mixin FormValidationMixin<T extends StatefulWidget> on State<T> implements FormMixin {
///   @override
///   final formKey = GlobalKey<FormState>();
///   @override
///   late final ValueNotifier<bool> formStateEmitter;
///   late final TextEditingController textEditingController;
///
///   @override
///   void initState() {
///     super.initState();
///     textEditingController = TextEditingController();
///     formStateEmitter = ValueNotifier(formValidityStatus());
///     trackValidity();
///   }
///
///   @override
///   void trackValidity() {
///     textEditingController.addListener(() {
///       formStateEmitter.value = formValidityStatus();
///     });
///   }
///
///   @override
///   bool formValidityStatus() {
///     return textEditingController.text.isNotEmpty;
///   }
///
///   @override
///   void submit() {
///     if (!(formKey.currentState?.validate() ?? true)) return;
///     AppLogger.info(textEditingController.text);
///   }
/// }
///
///
/// class FormWidget extends StatefulWidget {
///   const FormWidget({super.key});
///
///   @override
///   State<FormWidget> createState() => _FormWidgetState();
/// }
///
///
/// class _FormWidgetState extends State<FormWidget> with FormValidationMixin {
///   @override
///   Widget build(BuildContext context) {
///     return Form(
///       key: formKey,
///       autovalidateMode: AutovalidateMode.onUserInteraction,
///       child: Column(
///         children: [
///           TextFormField(
///             controller: textEditingController,
///             validator: (value) {
///               if (!value.hasValue) return "Please enter a value";
///               return null;
///             },
///           ),
///           ValueListenableBuilder<bool>(
///             valueListenable: formStateEmitter,
///             builder: (context, isValid, _) {
///               return ElevatedButton(
///                 onPressed: isValid ? submit : null,
///                 child: const Text("Submit"),
///               );
///             },
///           ),
///         ],
///       ),
///     );
///   }
/// }
/// ```
abstract class FormMixin {
  /// The global key used to uniquely identify and validate the [Form] widget.
  ///
  /// This key must be passed to the `key` property of the [Form] widget.
  /// It is typically used during [submit] to trigger standard form validation.
  final formKey = GlobalKey<FormState>();

  /// A notifier that emits the current validity status of the form.
  ///
  /// Listeners (such as submission buttons) can subscribe to this notifier
  /// to dynamically enable or disable themselves based on the form's validity.
  ValueNotifier<bool> get formStateEmitter;

  /// Registers listeners on form input controllers to track change events.
  ///
  /// This method is typically invoked in `initState` to monitor changes to
  /// text controllers, dropdowns, and other fields, updating [formStateEmitter]
  /// with the result of [formValidityStatus].
  void trackValidity();

  /// Computes and returns the overall validity status of the form.
  ///
  /// This is used to determine the initial and dynamic status of the form before
  /// full [FormState.validate] is called, enabling real-time UI feedback.
  ///
  /// Returns `true` if the form is valid, and `false` otherwise.
  bool formValidityStatus();

  /// Executes the form submission logic.
  ///
  /// This method should validate the fields via [formKey], and if valid,
  /// perform the final submission action (e.g. API request, navigation).
  void submit();
}

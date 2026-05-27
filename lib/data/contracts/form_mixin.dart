import 'package:flutter/material.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Data}
/// A contract for form management.
/// ```dart
/// mixin FormValidationMixin on State<StatefulWidget> implements FormMixin {
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
  final formKey = GlobalKey<FormState>();
  ValueNotifier<bool> get formStateEmitter;

  void trackValidity();
  bool formValidityStatus();
  void submit();
}

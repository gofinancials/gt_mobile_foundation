import 'package:flutter/widgets.dart'
    show
        BuildContext,
        MediaQuery,
        MediaQueryData,
        EdgeInsets,
        RenderBox,
        Size,
        Offset;

class ScalerDimension {
  late MediaQueryData _queryData;

  ScalerDimension(BuildContext context) {
    _queryData = MediaQuery.of(context);
  }

  double get topInset {
    return _queryData.padding.top;
  }

  double get bottomInset {
    return _queryData.viewInsets.bottom;
  }

  double get shortestSide {
    return _queryData.size.shortestSide;
  }

  double get longestSide {
    return _queryData.size.longestSide;
  }

  double get width {
    return _queryData.size.width;
  }

  double get height {
    return _queryData.size.height;
  }

  double setLongestSide(double percentage) {
    if (percentage == 0) return 0;
    return longestSide * (percentage / 100);
  }

  double setShortestSide(double percentage) {
    if (percentage == 0) return 0;
    return shortestSide * (percentage / 100);
  }

  double setHeight(double percentage) {
    if (percentage == 0) return 0;
    return height * (percentage / 100);
  }

  double setWidth(double percentage) {
    if (percentage == 0) return 0;
    return width * (percentage / 100);
  }
}

class ScalerFontSizer {
  late num _scale;

  double _x(BuildContext context) {
    final x = MediaQuery.of(context).size.shortestSide;
    return x > 428 ? 428 : x;
  }

  double _y(BuildContext context) {
    final y = MediaQuery.of(context).size.longestSide;
    return y > 926 ? 926 : y;
  }

  ScalerFontSizer(BuildContext context) {
    final y = _y(context);
    final x = _x(context);
    _scale = (x + y) / 4;
  }

  double sp(double? percentage) {
    return (_scale * ((percentage ?? 40) / 1000)).floorToDouble();
  }

  double px(double? pixels) {
    return (1000 * ((pixels ?? 14)) / _scale).toDouble();
  }
}

class ScalerInsets {
  late ScalerDimension sizer;

  ScalerInsets(BuildContext context) {
    sizer = ScalerDimension(context);
  }

  EdgeInsets get zero {
    return EdgeInsets.zero;
  }

  EdgeInsets all(double inset) {
    return EdgeInsets.all(sizer.setShortestSide(inset));
  }

  EdgeInsets get defaultHorizontalInsets {
    return symmetric(horizontal: 5);
  }

  EdgeInsets get defaultFormOnlyBottomInsets {
    return only(bottom: 3);
  }

  EdgeInsets get defaultVerticalInsets {
    return symmetric(vertical: 5);
  }

  EdgeInsets get defaultSymmetricInsets {
    return symmetric(horizontal: 5, vertical: 5);
  }

  EdgeInsets get defaultZeroTopInsets {
    return fromLTRB(5, 0, 5, 5);
  }

  EdgeInsets get defaultOnlyBottomInsets {
    return only(bottom: 5);
  }

  EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return EdgeInsets.only(
      top: sizer.setLongestSide(top),
      left: sizer.setShortestSide(left),
      bottom: sizer.setLongestSide(bottom),
      right: sizer.setShortestSide(right),
    );
  }

  EdgeInsets fromLTRB(
    double left,
    double top,
    double right,
    double bottom,
  ) {
    return EdgeInsets.fromLTRB(
      sizer.setShortestSide(left),
      sizer.setLongestSide(top),
      sizer.setShortestSide(right),
      sizer.setLongestSide(bottom),
    );
  }

  EdgeInsets symmetric({
    double vertical = 0,
    double horizontal = 0,
  }) {
    return EdgeInsets.symmetric(
      vertical: sizer.setLongestSide(vertical),
      horizontal: sizer.setShortestSide(horizontal),
    );
  }

  EdgeInsets copy(EdgeInsets insets) => insets;
}

class ScalerUtili {
  final BuildContext context;
  static const double textScaleFactor = 1;

  ScalerUtili(this.context);

  factory ScalerUtili.of(BuildContext context) => ScalerUtili(context);

  ScalerDimension get sizer => ScalerDimension(context);
  ScalerFontSizer get fontSizer => ScalerFontSizer(context);
  ScalerInsets get insets => ScalerInsets(context);

  Offset get position {
    final RenderBox box = context.findRenderObject() as RenderBox;
    return box.localToGlobal(Offset.zero);
  }

  Size get size {
    final RenderBox box = context.findRenderObject() as RenderBox;
    return box.size;
  }
}

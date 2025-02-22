import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';

import '../../../common/constants.dart';

class EmptySearch extends StatelessWidget {
  final String? title;
  final String? image;
  final double width;
  final double height;
  final EdgeInsets paddingImage;
  final TextStyle? textStyle;
  const EmptySearch({
    super.key,
    this.title,
    this.image,
    this.width = 120.0,
    this.height = 120.0,
    this.paddingImage = const EdgeInsets.only(bottom: 30),
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: paddingImage,
          child: FluxImage(
            imageUrl: image ?? kNoResult,
            width: width,
            height: height,
            fit: BoxFit.contain,
          ),
        ),
        Text(
          title ?? S.of(context).notFindResult,
          style: textStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

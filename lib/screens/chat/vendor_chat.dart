import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:quiver/strings.dart';

import '../../models/index.dart' show Product, User;
import 'chat_arguments.dart';
import 'chat_mixin.dart';
import 'scale_animation_mixin.dart';
import 'smartchat.dart';

class VendorChat extends StatefulWidget {
  final Store? store;
  final User? user;
  final Product? product;

  const VendorChat({
    this.store,
    this.user,
    this.product,
    super.key,
  });

  @override
  State<VendorChat> createState() => _VendorChatState();
}

class _VendorChatState extends State<VendorChat>
    with ChatMixin, ScaleAnimationMixin, SingleTickerProviderStateMixin {
  Store? get store => widget.store;

  User? get user => widget.user;

  @override
  List<Map> get supportedSmartChatOptions {
    final store = widget.store;
    if (store == null) {
      return super.supportedSmartChatOptions;
    }

    final options = [];
    if (isNotBlank(store.email) && store.showEmail && isNotBlank(store.name)) {
      options.add({
        'app': 'store',
        'description': S.of(context).chatWithStoreOwner,
        'iconData': Icons.home_work_outlined,
        'storeArguments': ChatArguments(
          senderUser: user,
          receiverEmail: store.chatEmail,
          receiverName: store.name,
          product: widget.product,
        ),
      });
    }
    if (store.socials != null && store.socials!['facebook'] != null) {
      options.add({
        'app': store.socials!['facebook']!.contains('http')
            ? store.socials!['facebook']
            : 'https://m.me/${store.socials!["facebook"]}',
        'description': S.of(context).chatViaFacebook,
        'iconData': Icons.facebook
      });
    }
    if (isNotBlank(store.phone) && store.showPhone) {
      options.add({
        'app': 'https://wa.me/${store.phone}',
        'description': S.of(context).chatViaWhatApp,
        'iconData': Icons.chat,
      });
      options.add({
        'app': 'tel:${store.phone}',
        'description': S.of(context).callToVendor,
        'iconData': Icons.phone,
      });
      options.add({
        'app': 'sms://${store.phone}',
        'description': S.of(context).sendSMStoVendor,
        'iconData': Icons.sms,
      });
    }

    return List<Map>.from(options);
  }

  @override
  Widget build(BuildContext context) {
    if (store == null) {
      return const SmartChat();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: ScaleTransition(
        scale: scaleAnimation,
        alignment: Alignment.center,
        child: FloatingActionButton(
          heroTag: null,
          backgroundColor: Theme.of(context).colorScheme.surface,
          onPressed: () async {
            if (scaleAnimationController.isCompleted) {
              Future.delayed(Duration.zero, scaleAnimationController.reverse);
              await Future.delayed(const Duration(milliseconds: 80), () {});
              await showActionSheet(
                context: context,
              );
              await scaleAnimationController.forward();
            }
          },
          child: Icon(
            CupertinoIcons.conversation_bubble,
            color: Theme.of(context).primaryColor,
            size: 32,
          ),
        ),
      ),
    );
  }

  @override
  TickerProvider get vsync => this;
}

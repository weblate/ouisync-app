import 'package:flutter/material.dart';
import 'package:ouisync_plugin/ouisync_plugin.dart';
import 'package:share_plus/share_plus.dart';

import '../../utils/utils.dart';

class ShareRepository extends StatefulWidget {
  ShareRepository({
    required this.repository,
    required this.repositoryName
  });

  final Repository repository;
  final String repositoryName;

  @override
  State<StatefulWidget> createState() => _ShareRepositoryState();
}

class _ShareRepositoryState extends State<ShareRepository> {
  ValueNotifier<AccessMode> _accessMode =
    ValueNotifier<AccessMode>(AccessMode.blind);

  final ValueNotifier<String> _shareToken =
    ValueNotifier<String>(Strings.messageError);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      initialData: '',
      future: createShareToken(repo: widget.repository, name: widget.repositoryName, accessMode: _accessMode.value),
      builder: (context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasError) {
          _shareToken.value = Strings.messageAck;
          return Text(Strings.messageErrorCreatingToken);
        }

        if (snapshot.hasData) {
          _shareToken.value = snapshot.data!;

          return Container(
            padding: Dimensions.paddingBottomSheet,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Fields.bottomSheetHandle(context),
                Fields.bottomSheetTitle(
                  Strings.titleShareRepository
                  .replaceAll(Strings.replacementName, widget.repositoryName)
                ),
                Fields.iconLabel(
                  icon: Icons.lock_rounded,
                  text: Strings.iconAccessMode,
                ),
                _buildAccessModeDropdown(),
                Dimensions.spacingVertical,
                _buildAccessModeDescription(),
                Dimensions.spacingVertical,
                Fields.iconLabel(
                  icon: Icons.supervisor_account_rounded,
                  text: Strings.iconShareTokenWithPeer,
                ),
                _buildShareBox()
              ]
            ),
          );
        }

        _shareToken.value = Strings.messageCreatingToken;

        return Container(
          height: Dimensions.sizeCircularProgressIndicatorAverage.height,
          width: Dimensions.sizeCircularProgressIndicatorAverage.width,
          child: CircularProgressIndicator(strokeWidth: Dimensions.strokeCircularProgressIndicatorSmall,)
        );
      }
    );
  }

  Future<String> createShareToken({
    required Repository repo,
    required String name,
    required AccessMode accessMode
  }) async {
    final shareToken = await repo.createShareToken(accessMode: accessMode, name: name);
    // Print this only while debugging, tokens are secrets that shouldn't be logged otherwise.
    //print('Token for sharing repository $name: $shareToken (${accessMode.name})');
    return shareToken.token;
  }

  Widget _buildAccessModeDropdown() {
    return Container(
      padding: Dimensions.paddingActionBox,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(Dimensions.radiusMicro)),
        border: Border.all(
          color: Colors.black45,
          width: 1.0,
          style: BorderStyle.solid
        ),
        color: Colors.white,
      ),
      child: ValueListenableBuilder(
        valueListenable: _accessMode,
        builder:(context, value, child) =>
          DropdownButton(
            isExpanded: true,
            value: value,
            underline: SizedBox(),
            items: AccessMode.values.map((AccessMode element) {
              return DropdownMenuItem(
                value: element,
                child: Text(
                  element.name,
                  style: TextStyle(
                    fontSize: Dimensions.fontAverage
                  ),
                )
              );
            }).toList(),
            onChanged: (accessMode) async {
              print('Access mode: $accessMode');
              _accessMode.value = accessMode as AccessMode;

              final token = await createShareToken(
                repo: widget.repository,
                name: widget.repositoryName,
                accessMode: accessMode
              );

              _shareToken.value = token;
            },
          )
      )
    );
  }

  Widget _buildAccessModeDescription() =>
    ValueListenableBuilder(
      valueListenable: _accessMode,
      builder:(context, accessMode, child) =>
        Fields.constrainedText(
          _tokenDescription(accessMode as AccessMode),
          flex: 0,
          fontSize: Dimensions.fontSmall,
          fontWeight: FontWeight.normal,
          color: Colors.black54
        )
    );

  Widget _buildShareBox() => Container(
    padding: Dimensions.paddingActionBox,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(Dimensions.radiusMicro)),
      border: Border.all(
        color: Colors.black45,
        width: 1.0,
        style: BorderStyle.solid
      ),
      color: Colors.white,
    ),
    child: Row(
      children: [
        ValueListenableBuilder(
          valueListenable: _shareToken,
          builder:(context, value, child) =>
            Fields.constrainedText(
              value as String,
              softWrap: false,
              textOverflow: TextOverflow.ellipsis,
              color: Colors.black
            )
        ),
        Fields.actionIcon(
          const Icon(Icons.content_copy_rounded),
          onPressed: () async {
            await copyStringToClipboard(_shareToken.value);
            showToast(Strings.messageTokenCopiedToClipboard);
          },
        ),
        Fields.actionIcon(
          const Icon(Icons.share_outlined),
          onPressed: () => Share.share(_shareToken.value),
        ),
      ],
    )
  );

  String _tokenDescription(AccessMode accessMode) {
    return Constants.accessModeDescriptions.values.elementAt(accessMode.index);
  }
}

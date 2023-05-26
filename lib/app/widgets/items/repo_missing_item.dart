import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';
import '../../models/models.dart';
import '../../utils/loggers/ouisync_app_logger.dart';
import '../../utils/utils.dart';

class RepoMissing extends StatelessWidget with OuiSyncAppLogger {
  RepoMissing({required this.repoData});

  final RepoMissingItem repoData;

  @override
  Widget build(BuildContext context) => Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Fields.autosizeText(repoData.name),
            Fields.autosizeText(S.current.messageRepoMissing,
                fontSize: Dimensions.fontSmall)
          ],
        ),
      );
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../../generated/l10n.dart';
import '../../cubits/cubits.dart';
import 'logs_actions.dart';
import 'navigation_tile_mobile.dart';

class LogsSectionMobile extends AbstractSettingsSection {
  final ReposCubit repos;
  final StateMonitorIntCubit panicCounter;
  final LogsActions actions;

  LogsSectionMobile({
    required this.repos,
    required this.panicCounter,
  }) : actions = LogsActions(
          stateMonitor: repos.session.rootStateMonitor,
        );

  @override
  Widget build(BuildContext context) => SettingsSection(
        title: Text(S.current.titleLogs),
        tiles: [
          NavigationTileMobile(
            title: Text(S.current.actionSave),
            leading: Icon(Icons.save),
            onPressed: actions.saveLogs,
          ),
          NavigationTileMobile(
            title: Text(S.current.actionShare),
            leading: Icon(Icons.share),
            onPressed: actions.shareLogs,
          ),
          NavigationTileMobile(
            title: Text(S.current.messageView),
            leading: Icon(Icons.visibility),
            onPressed: actions.viewLogs,
          ),
          CustomSettingsTile(
            child: BlocBuilder<StateMonitorIntCubit, int?>(
                bloc: panicCounter,
                builder: (context, count) {
                  if ((count ?? 0) > 0) {
                    final color = Theme.of(context).colorScheme.error;
                    return SettingsTile(
                      title: Text(
                        S.current.messageLibraryPanic,
                        style: TextStyle(color: color),
                      ),
                      leading: Icon(Icons.error, color: color),
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                }),
          ),
        ],
      );
}

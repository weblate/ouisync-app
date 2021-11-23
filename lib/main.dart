import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ouisync_plugin/ouisync_plugin.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/bloc/blocs.dart';
import 'app/utils/actions.dart';
import 'app/utils/utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Bloc.observer = SimpleBlocObserver();

  Repository? defaultRepository;

  final appDir = (await getApplicationSupportDirectory()).path;
  final repositoriesDir = '$appDir/repositories';
  final sessionStore = '$appDir/config.db';

  final localRepositoriesList = loadLocalRepositories(repositoriesDir).map((e) => e.substring(0, e.lastIndexOf('.'))).toList();
  final latestRepositoryOrDefaultName = await getLatestRepositoryOrDefault(localRepositoriesList);
  
  Settings.initSettings(
    appDir,
    repositoriesDir,
    sessionStore,
    latestRepositoryOrDefaultName
  );

  final session = await Session.open(sessionStore);
  if (latestRepositoryOrDefaultName.isNotEmpty) {
   defaultRepository = await Repository.open(session, '$repositoriesDir/$latestRepositoryOrDefaultName.db'); 
  }
  
  runApp(OuiSyncApp(
    appDir: appDir,
    repositoriesDir: repositoriesDir,
    session: session,
    defaultRepository: defaultRepository,
    defaultRepositoryName: latestRepositoryOrDefaultName,
  ));
}

List<String> loadLocalRepositories(String repositoriesDir) {
  final repositoryFiles = <String>[];
  if (io.Directory(repositoriesDir).existsSync()) {
    repositoryFiles.addAll(io.Directory(repositoriesDir).listSync().map((e) => removeParentFromPath(e.path)).toList());
    repositoryFiles.removeWhere((e) => !e.endsWith('db'));
  }

  print('Local repositories found: $repositoryFiles');
  return repositoryFiles;
}

Future<String> getLatestRepositoryOrDefault(List<String> localRepositories) async {
  if (localRepositories.isEmpty) {
    return '';
  }

  final defaultRepository = localRepositories.first;
  final latestRepository = await Settings.readSetting(Constants.currentRepositoryKey);

  if (latestRepository == null) {
    return defaultRepository;
  }
  if (!localRepositories.contains(latestRepository)) {
    return defaultRepository;
  }

  return latestRepository;
}

Future<Repository> openDefaultRepository(session, repositoryStore) async {
  return await Repository.open(session, repositoryStore);
}

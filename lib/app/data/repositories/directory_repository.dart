import 'package:chunked_stream/chunked_stream.dart';
import 'package:ouisync_plugin/ouisync_plugin.dart';

import '../../models/models.dart';
import '../../utils/utils.dart';

class DirectoryRepository {
  const DirectoryRepository({
    required this.repository
  });

  final Repository repository;

  _openDirectory(repository, path) async => 
    await Directory.open(repository, path);

  _openFile(repository, path) async => 
    await File.open(repository, path);

  Future<BasicResult> createFile(String newFilePath) async {
    BasicResult createFileResult;
    String error = '';

    File? newFile;

    try {
      print('Creating file $newFilePath');

      newFile = await File.create(repository, newFilePath);
    } catch (e) {
      print('Error creating file $newFilePath: $e');
      error = e.toString();
    } finally {
      newFile!.close(); // TODO: Necessary?
    }

    createFileResult = CreateFileResult(functionName: 'createFile', result: newFile);
    if (error.isNotEmpty) {
      createFileResult.errorMessage = error;
    }

    return createFileResult;
  }

  Future<BasicResult> writeFile(String filePath, Stream<List<int>> fileStream) async {
    print('Writing file $filePath');
    
    BasicResult writeFileResult;
    String error = '';

    int offset = 0;
    final file = await _openFile(repository, filePath);

    try {
      final streamReader = ChunkedStreamIterator(fileStream);
      while (true) {
        final buffer = await streamReader.read(bufferSize);
        print('Buffer size: ${buffer.length} - offset: $offset');

        if (buffer.isEmpty) {
          print('The buffer is empty; reading from the stream is done!');
          break;
        }

        await file.write(offset, buffer);
        offset += buffer.length;
      }
    } catch (e) {
      print('Exception writing the fie $filePath:\n${e.toString()}');
      error = 'Writing to the file $filePath failed';
    } finally {
      file.close();
    }

    writeFileResult = WriteFileResult(functionName: 'writeFile', result: file);
    if (error.isNotEmpty) {
      writeFileResult.errorMessage = error;
    }

    return writeFileResult; 
  }

  Future<BasicResult> readFile(String filePath, { String action = '' }) async {
    BasicResult readFileResult;
    String error = '';

    final content = <int>[];
    final file = await _openFile(repository, filePath);    

    try {
      final length = await file.length;
      content.addAll(await file.read(0, length));  
    } catch (e) {
      print('Exception reading file $filePath:\n${e.toString()}');
      error = 'Read file $filePath failed';
    } finally {
      file.close();
    }

    readFileResult = action.isEmpty
    ? ReadFileResult(functionName: 'readFile', result: content)
    : ShareFileResult(functionName: 'readFile', result: content, action: action);
    if (error.isNotEmpty) {
      readFileResult.errorMessage = error;
    }

    return readFileResult;
  }

  Future<BasicResult> deleteFile(String filePath) async {
    BasicResult deleteFileResult;
    String error = '';

    try {
      await File.remove(repository, filePath);
    } catch (e) {
      print('Exception deleting file $filePath:\n${e.toString()}');
      error = 'Delete file $filePath failed';
    }

    deleteFileResult = DeleteFileResult(functionName: 'deleteFile', result: 'OK');
    if (error.isNotEmpty) {
      deleteFileResult.errorMessage = error;
    }

    return deleteFileResult;
  }

  Future<BasicResult> createFolder(String path)  async {
    BasicResult createFolderResult;
    String error = '';

    bool created = false;

    try {
      print('Creating folder $path');

      await Directory.create(repository, path);
      created = true;
    } catch (e) {
      print('Error creating folder $path: $e');

      created = false;
      error = e.toString();
    }

    createFolderResult = CreateFolderResult(functionName: 'createFolder', result: created);
    if (error.isNotEmpty) {
      createFolderResult.errorMessage = error;
    }

    return createFolderResult;
  }

  Future<BasicResult> getFolderContents(String path) async {
    print("Getting folder $path contents");
  
    BasicResult getContentsResult;
    String error = '';

    final returnedContent = <BaseItem>[];
    final directory = await _openDirectory(repository, path);
    
    try {
      final iterator = directory.iterator;
      while (iterator.moveNext()) {
        final returned =  await _castToBaseItem(
          path,
          iterator.current.name,
          iterator.current.type,
          0.0
        );

        returnedContent.add(returned);
      } 
    } catch (e) {
      print('Error traversing directory $path: $e');
      error = e.toString();
    } finally {
      directory.close();
    }
    
    getContentsResult = GetContentResult(functionName: 'getFolderContents', result: returnedContent);
    if (error.isNotEmpty) {
      getContentsResult.errorMessage = error;
    }

    return getContentsResult;
  }

  Future<List<BaseItem>> getContentsRecursive(String path) async {
    final contentNodes = <BaseItem>[];

    final directory = await _openDirectory(repository, path);
    if (directory.isEmpty) {
      print('Folder $path is empty.');

      directory.close();
      return <BaseItem>[];
    }

    try {
      final iterator = directory.iterator;
      while (iterator.moveNext()) {
        final newNode = await _castToBaseItem(
          path,
          iterator.current.current,
          iterator.current.type,
          0.0
        );

        if (newNode.itemType == ItemType.folder) {
          final itemPath = path == '/'
          ? '/${iterator.current.current}'
          : '$path/${iterator.current.current}';

          (newNode as FolderItem).items = await getContentsRecursive(itemPath);  
        }
        
        contentNodes.add(newNode);
      }  
    } catch (e) {
      print('Error traversing directory $path: $e');
    } finally {
      directory.close();
    }

    return contentNodes;
  }

  Future<BaseItem> _castToBaseItem(String path, String name, EntryType type, double size) async {
    final itemPath = path == '/'
    ? '/$name'
    : '$path/$name';

    if (type == EntryType.directory) {
      return FolderItem(
        name: name,
        path: itemPath,
        size: size,
        syncStatus: SyncStatus.idle,
        itemType: ItemType.folder,
        items: <BaseItem>[]
      );
    }

    if (type == EntryType.file) {
      String fileType = extractFileTypeFromName(name);

      return FileItem(
        name: name,
        extension: fileType,
        path: itemPath,
        size: size,
        syncStatus: SyncStatus.idle
      ); 
    }

    return <BaseItem>[].single;
  }

  Future<BasicResult> deleteFolder(String path) async {
    BasicResult deleteFolderResult;
    String error = '';

    try {
      await Directory.remove(repository, path);
    } catch (e) {
      print('Exception deleting folder $path:\n${e.toString()}');
      error = 'Delete folder $path failed';
    }

    deleteFolderResult = DeleteFolderResult(functionName: 'deleteFolder', result: 'OK');
    if (error.isNotEmpty) {
      deleteFolderResult.errorMessage = error;
    }

    return deleteFolderResult;
  }
}
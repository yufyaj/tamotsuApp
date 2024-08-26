import 'package:flutter/material.dart';
import 'package:multi_image_picker_plus/multi_image_picker_plus.dart';

Future<void> _pickSingleImage(context) async {
  final ColorScheme colorScheme = Theme.of(context).colorScheme;

  Asset? result;

  const AlbumSetting albumSetting = AlbumSetting(
    fetchResults: {
      PHFetchResult(
        type: PHAssetCollectionType.smartAlbum,
        subtype: PHAssetCollectionSubtype.smartAlbumUserLibrary,
      ),
    },
  );

  const SelectionSetting selectionSetting = SelectionSetting(
    min: 1,
    max: 1,
    unselectOnReachingMax: false,
  );

  final ThemeSetting themeSetting = ThemeSetting(
    backgroundColor: Colors.white,
    selectionFillColor: Colors.blue,
    selectionStrokeColor: Colors.blue,
  );

  final CupertinoSettings iosSettings = CupertinoSettings(
    fetch: const FetchSetting(album: albumSetting),
    theme: themeSetting,
    selection: selectionSetting,
  );

  try {
    result = await MultiImagePicker.pickImages(
      selectedAssets: [],
      iosOptions: IOSOptions(
        doneButton: UIBarButtonItem(title: 'Confirm', tintColor: Colors.green),
        cancelButton: UIBarButtonItem(title: 'Cancel', tintColor: Colors.green),
        albumButtonColor: colorScheme.primary,
        settings: iosSettings,
      ),
      androidOptions: AndroidOptions(
        actionBarColor: Colors.green,
        actionBarTitleColor: colorScheme.surface,
        statusBarColor: colorScheme.surface,
        actionBarTitle: "画像を選択",
        allViewTitle: "すべての画像",
        useDetailsView: false,
        selectCircleStrokeColor: colorScheme.primary,
      ),
    ).then((assets) => assets.isNotEmpty ? assets.first : null);
  } on Exception catch (e) {
    rethrow;
  }

  selectedImage = result;
}

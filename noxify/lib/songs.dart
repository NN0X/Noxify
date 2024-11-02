import 'package:flutter/services.dart' show rootBundle;

class Song {
  final int id;
  String title;
  String artist;
  String album;

  Song({
    required this.id,
    this.title = '',
    this.artist = '',
    this.album = '',
  });

  void load(int id) async {
    // load song data from file
    String file;
    try {
      file = await rootBundle.loadString('resources/songs.local');
      print('Loaded song data: $id');
    } catch (e) {
      print('Error loading song data: $id');
      return;
    }
    final songsData = file.toString().split('\n');

    for (var i = 0; i < songsData.length; i += 5) {
      if (int.parse(songsData[i]) == id) {
        title = songsData[i + 1];
        artist = songsData[i + 2];
        album = songsData[i + 3];
        break;
      }
    }
  }

  void printSong() {
    print('Song ID: $id');
    print('Title: $title');
    print('Artist: $artist');
    print('Album: $album');
  }
}

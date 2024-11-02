import 'package:flutter/services.dart' show rootBundle;

import 'songs.dart';

class Playlist {
  final int id;
  String title;
  String author;
  List<Song> songs;

  Playlist({
    required this.id,
    this.title = '',
    this.author = '',
    this.songs = const [],
  });

  void load(int id) async {
    // load name and author from playlists.local file
    String file;
    try {
      file = await rootBundle.loadString('resources/playlists.local');
      print('Loaded playlist data: $id');
    } catch (e) {
      print('Error loading playlist data: $id');
      return;
    }
    final playlistsData = file.toString().split('\n');
    for (var i = 0; i < playlistsData.length; i += 4) {
      if (int.parse(playlistsData[i]) == id) {
        title = playlistsData[i + 1];
        author = playlistsData[i + 2];
        break;
      }
    }

    // load song ids from playlist file 'resources/playlists/$id.playlist'
    try {
      file = await rootBundle.loadString('resources/playlists/$id.playlist');
      print('Loaded playlist songs: $id');
    } catch (e) {
      print('Error loading playlist songs: $id');
      return;
    }
    songs = [];
    final songsData = file.toString().split('\n');
    print("File: ");
    print(file.toString());
    for (var i = 0; i < songsData.length; i++) {
      if (int.tryParse(songsData[i]) == null) {
        continue;
      }
      final song = Song(id: int.parse(songsData[i]));
      song.load(song.id);
      songs.add(song);
    }
  }

  void printPlaylist() {
    print('Playlist ID: $id');
    print('Title: $title');
    print('Songs:');
    for (var song in songs) {
      print(song);
    }
  }
}

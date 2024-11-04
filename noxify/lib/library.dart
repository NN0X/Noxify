import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

import 'noxify.dart';
import 'songs.dart';
import 'playlists.dart';

class AllData {
  final List<Song> songsLocal;
  final List<Song> songsUpstream;
  final List<Playlist> playlists;

  AllData({
    required this.songsLocal,
    required this.songsUpstream,
    required this.playlists,
  });

  bool isEmpty() =>
      songsLocal.isEmpty && songsUpstream.isEmpty && playlists.isEmpty;
}

class LibraryPage extends StatelessWidget {
  const LibraryPage({Key? key}) : super(key: key);

  Future<List<Song>> getLocalSongs() async {
    var songsLocal = <Song>[];

    // load song IDs from file
    String file;
    try {
      file = await rootBundle.loadString('resources/songs.local');
      print('Loaded song IDs');
    } catch (e) {
      print('Error loading song IDs');
      return songsLocal;
    }
    final lines = file.toString().split('\n');
    final songIDs = <int>[];
    for (var i = 0; i < lines.length; i += 5) {
      final id = int.parse(lines[i]);
      try {
        await rootBundle.load('resources/audio/$id.mp3');
      } catch (e) {
        continue;
      }
      songIDs.add(id);
    }

    for (var id in songIDs) {
      final s = Song(id: id);
      s.load(id);
      songsLocal.add(s);
    }

    // simulate loading delay
    //await Future.delayed(const Duration(seconds: 1));

    // simulate no songs found
    //songs = [];

    // simulate error
    //throw Exception('Error loading songs');

    return songsLocal;
  }

  Future<List<Song>> getUpstreamSongs() async {
    var songsUpstream = <Song>[];
    return songsUpstream;
  }

  Future<List<Playlist>> getPlaylists() async {
    var playlists = <Playlist>[];
    String file;
    try {
      file = await rootBundle.loadString('resources/playlists.local');
      print('Loaded playlists IDs');
    } catch (e) {
      print('Error loading playlists IDs');
      return playlists;
    }

    final lines = file.toString().split('\n');
    final playlistIDs = <int>[];
    for (var i = 0; i < lines.length; i += 4) {
      final id = int.parse(lines[i]);
      playlistIDs.add(id);
    }

    for (var id in playlistIDs) {
      final p = Playlist(id: id);
      p.load(id);
      playlists.add(p);
    }

    return playlists;
  }

  Future<AllData> getAllData() async {
    final songsLocal = await getLocalSongs();
    final songsUpstream = await getUpstreamSongs();
    final playlists = await getPlaylists();
    return AllData(
      songsLocal: songsLocal,
      songsUpstream: songsUpstream,
      playlists: playlists,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AllData>(
      future: getAllData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error loading songs"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty()) {
          return const Center(child: Text("No songs found"));
        } else {
          var songsLocal = snapshot.data!.songsLocal;
          var songsUpstream = snapshot.data!.songsUpstream;
          var playlists = snapshot.data!.playlists;

          var songsAll = <Song>[];
          for (var song in songsLocal) {
            if (!songsAll.contains(song)) {
              songsAll.add(song);
            }
          }
          for (var song in songsUpstream) {
            if (!songsAll.contains(song)) {
              songsAll.add(song);
            }
          }

          final noxifyState = Provider.of<NoxifyState>(context);
          final screenHeight = MediaQuery.sizeOf(context).height;
          final screenWidth = MediaQuery.sizeOf(context).width;

          return Center(
            child: Row(
              children: [
                if (noxifyState.isSongsFocused)
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(
                          height: screenHeight *
                              0.04, // Initial SizedBox at the top
                        ),
                        Container(
                          padding: EdgeInsets.all(screenWidth > 600 ? 20 : 0),
                          alignment: Alignment.center,
                          color: Colors.black54,
                          child: ListTile(
                            title: Text(
                              'Songs',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth > 600 ? 30 : 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: songsLocal.isNotEmpty
                                ? () {
                                    noxifyState.isPlaylistsFocused =
                                        !noxifyState.isPlaylistsFocused;
                                  }
                                : null,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.only(
                                bottom: screenHeight *
                                    0.2), // Padding at the bottom
                            itemCount: songsAll.length, // Directly count songs
                            itemBuilder: (context, index) {
                              final song = songsAll[index]; // Get the song
                              return Column(
                                children: [
                                  Container(
                                    color: Colors.black54,
                                    child: ListTile(
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              song.title,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize:
                                                    screenWidth > 600 ? 20 : 10,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          // if song in upstream songs
                                          if (songsLocal.contains(
                                              song)) // Check if song is in upstream songs
                                            const Icon(Icons.check)
                                          else
                                            const Icon(Icons.cloud),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          if (screenWidth > 600 ||
                                              !noxifyState.isPlaylistsFocused)
                                            Image.asset(
                                              'resources/covers/${song.id}.jpg',
                                              width:
                                                  screenWidth > 600 ? 80 : 50,
                                              height:
                                                  screenWidth > 600 ? 80 : 50,
                                            ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        song.artist,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth > 600 ? 15 : 8,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () {
                                        noxifyState.nextSongs.insert(0, song);
                                        noxifyState.skipNext(true);
                                      },
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          height: screenHeight > 1200
                              ? screenHeight * 0.08
                              : screenHeight * 0.12,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(
                  width: 5,
                ),
                if (noxifyState.isPlaylistsFocused)
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(
                          height: screenHeight *
                              0.04, // Initial SizedBox at the top
                        ),
                        Container(
                          padding: EdgeInsets.all(screenWidth > 600 ? 20 : 0),
                          alignment: Alignment.center,
                          color: Colors.black54,
                          child: ListTile(
                            title: Text(
                              'Playlists',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth > 600 ? 30 : 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: playlists.isNotEmpty
                                ? () {
                                    noxifyState.isSongsFocused =
                                        !noxifyState.isSongsFocused;
                                  }
                                : null,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Expanded(
                          // Wrap ListView with another Expanded to fill the remaining space
                          child: ListView.builder(
                            padding: EdgeInsets.only(
                                bottom: screenHeight *
                                    0.2), // Padding at the bottom
                            itemCount:
                                playlists.length, // Directly count playlists
                            itemBuilder: (context, index) {
                              final playlist =
                                  playlists[index]; // Get the playlist
                              return Column(
                                children: [
                                  Container(
                                    color: Colors.black54,
                                    child: ListTile(
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              playlist.title,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize:
                                                    screenWidth > 600 ? 20 : 10,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (screenWidth > 600 ||
                                              !noxifyState.isSongsFocused)
                                            Image.asset(
                                              'resources/albums/${playlist.id}.jpg',
                                              width:
                                                  screenWidth > 600 ? 80 : 50,
                                              height:
                                                  screenWidth > 600 ? 80 : 50,
                                            ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        playlist.author,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth > 600 ? 15 : 8,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () {
                                        noxifyState.loadPlaylist(playlist);
                                      },
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          height: screenHeight > 1200
                              ? screenHeight * 0.08
                              : screenHeight * 0.12,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }
      },
    );
  }
}

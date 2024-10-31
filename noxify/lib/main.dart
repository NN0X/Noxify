import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'dart:typed_data';

void main() async {
  runApp(const Noxify());
}

class Noxify extends StatelessWidget {
  const Noxify({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NoxifyState(),
      child: Consumer<NoxifyState>(
        builder: (context, noxifyState, child) {
          return MaterialApp(
            title: 'Noxify',
            theme: ThemeData(
              brightness: Brightness.light,
              primaryColor: Colors.deepPurple,
              scaffoldBackgroundColor: Colors.white,
              navigationRailTheme: const NavigationRailThemeData(
                backgroundColor: Colors.white,
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primaryColor: Colors.deepPurple,
              scaffoldBackgroundColor: Colors.black,
              navigationRailTheme: const NavigationRailThemeData(
                backgroundColor: Colors.black,
              ),
            ),
            themeMode: noxifyState.themeMode,
            home: const NoxifyHomePage(),
          );
        },
      ),
    );
  }
}

// load audio file function
Future<Uint8List> loadAudioFile(String path) async {
  ByteData file;
  try {
    file = await rootBundle.load(path);
    print('Loaded audio file: $path');
    return file.buffer.asUint8List();
  } catch (e) {
    print('Error loading audio file: $path');
    return Uint8List(0);
  }
}

class NoxifyState extends ChangeNotifier {
  var isDarkMode = true;
  var themeMode = ThemeMode.dark;
  var isNavRail = false;
  var searchQuery = '';

  final player = AudioPlayer();
  var isLooping = false;
  var isAlbumLoaded = false;
  var isShuffle = false;
  var isSongLoaded = false;
  var isPlaying = false;
  var currentSongID = -1;
  var currentSong = '-';
  var currentArtist = '-';
  var currentAlbum = '-';
  var currentSongDuration = 0.0;
  var currentSongPosition = 0.0;
  var volume = 0.5;
  var previousSongs = <int>[];
  var nextSongs = <int>[];

  var songTimeString = '';
  var songDurationString = '';

  void toggleDarkMode() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  void toggleNavRail() {
    isNavRail = !isNavRail;
    notifyListeners();
  }

  void togglePlaying() {
    isPlaying = !isPlaying;
    if (isPlaying) {
      player.resume();
    } else {
      player.pause();
    }
    notifyListeners();
  }

  void toggleLooping() {
    isLooping = !isLooping;
    if (isLooping) {
      player.setReleaseMode(ReleaseMode.loop);
    } else {
      player.setReleaseMode(ReleaseMode.release);
    }
    notifyListeners();
  }

  void toggleShuffle() {
    isShuffle = !isShuffle;
    notifyListeners();
  }

  void skipPrevious() {
    Song previousSong;
    if (previousSongs.isNotEmpty) {
      previousSong = Song(id: previousSongs.removeLast());
      previousSong.load(previousSong.id);
      loadSong(previousSong);
    }
  }

  void skipNext() {
    Song nextSong;
    if (nextSongs.isNotEmpty) {
      nextSong = Song(id: nextSongs.removeAt(0));
      nextSong.load(nextSong.id);
      loadSong(nextSong);
    }
  }

  void updateSongTime(Duration p) {
    if (currentSongDuration == 0.0) {
      notifyListeners();
      return;
    }
    currentSongPosition = p.inSeconds / currentSongDuration;
    if (currentSongPosition >= 1.0) {
      currentSongPosition = 0.0;
    }
    if (currentSongPosition < 0.0) {
      currentSongPosition = 0.0;
    }
    final songTime = currentSongDuration * currentSongPosition;

    final songTimeMinutes = (songTime / 60).floor();
    final songTimeSeconds = (songTime % 60).floor();
    final songDurationMinutes = (currentSongDuration / 60).floor();
    final songDurationSeconds = (currentSongDuration % 60).floor();

    songTimeString =
        '$songTimeMinutes:${songTimeSeconds.toString().padLeft(2, '0')}';
    songDurationString =
        '$songDurationMinutes:${songDurationSeconds.toString().padLeft(2, '0')}';
    notifyListeners();
  }

  void loadSong(Song song) {
    if (currentSongID == song.id) {
      // restart song
      isPlaying = true;
      player.seek(const Duration(seconds: 0));
      player.resume();
      return;
    }

    if (isSongLoaded) {
      player.stop();
      previousSongs.add(song.id);
    }
    currentSong = song.title;
    currentArtist = song.artist;
    currentAlbum = song.album;

    loadAudioFile('resources/audio/${song.id}.mp3').then((audioFile) {
      player.play(BytesSource(audioFile));
      currentSongID = song.id;
    });
    player.setVolume(volume);
    isSongLoaded = true;
    isPlaying = true;
    notifyListeners();
  }
}

class NoxifyHomePage extends StatefulWidget {
  const NoxifyHomePage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _NoxifyHomePageState createState() => _NoxifyHomePageState();
}

class _NoxifyHomePageState extends State<NoxifyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = const HomePage();
        break;
      case 1:
        page = const LibraryPage();
        break;
      case 2:
        page = const FoundPage();
        break;
      case 3:
        page = const SettingsPage();
        break;
      default:
        throw UnimplementedError("No page for index $selectedIndex");
    }

    final noxifyState = Provider.of<NoxifyState>(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    noxifyState.player.onDurationChanged.listen((Duration d) {
      noxifyState.currentSongDuration = d.inSeconds.toDouble();
    });

    noxifyState.player.onPositionChanged
        .listen((Duration p) => noxifyState.updateSongTime(p));

    noxifyState.player.onPlayerComplete.listen((_) {
      if (!noxifyState.isLooping) {
        noxifyState.isPlaying = false;
        noxifyState.player.pause();
        noxifyState.skipNext();
      } else {
        noxifyState.player.pause();
        noxifyState.player.seek(const Duration(seconds: 0));
        noxifyState.player.resume();
      }
    });

    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(screenHeight * 0.001),
              child: AppBar(),
            ),
            body: Row(
              children: [
                SafeArea(
                  child: Stack(
                    children: [
                      Padding(
                        // add dynamic top padding based on screen height
                        padding: EdgeInsets.only(top: screenHeight * 0.03),
                        child: SizedBox(
                          width: screenWidth > 600 ? null : screenWidth * 0.15,
                          child: NavigationRail(
                            extended: noxifyState.isNavRail,
                            minExtendedWidth: 180,
                            destinations: const [
                              // button for toggling nav rail
                              NavigationRailDestination(
                                icon: Icon(Icons.home),
                                selectedIcon: Icon(Icons.home),
                                label: Text('Home'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.library_music),
                                selectedIcon: Icon(Icons.library_music),
                                label: Text('Library'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.search),
                                selectedIcon: Icon(Icons.search),
                                label: Text('Search'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.settings),
                                selectedIcon: Icon(Icons.settings),
                                label: Text('Settings'),
                              ),
                            ],
                            selectedIndex: selectedIndex,
                            onDestinationSelected: (int index) {
                              setState(() {
                                selectedIndex = index;
                              });
                            },
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          if (screenWidth > 600)
                            SizedBox(
                              child: IconButton(
                                icon: const Icon(Icons.menu),
                                onPressed: () {
                                  noxifyState.toggleNavRail();
                                },
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, 0),
                            radius: 1.5,
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).scaffoldBackgroundColor,
                            ],
                          ),
                        ),
                        child: page,
                      ),
                      Container(
                        height: screenHeight * 0.05,
                        width: double.infinity,
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: screenHeight * 0.002,
                            bottom: screenHeight * 0.004,
                            left: screenWidth * 0.05,
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding:
                                    EdgeInsets.only(top: screenWidth * 0.002),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: screenWidth * 0.35,
                                      child: SearchBar(
                                        hintText: 'Search',
                                        onChanged: (value) {
                                          noxifyState.searchQuery = value;
                                        },
                                        onSubmitted: (_) {
                                          print(noxifyState.searchQuery);
                                          setState(() {
                                            selectedIndex = 2;
                                          });
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.search),
                                      onPressed: () {
                                        print(noxifyState.searchQuery);
                                        setState(() {
                                          selectedIndex = 2;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: screenWidth > 600 ? null : screenWidth * 0.15,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.006),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            shape: const CircleBorder(),
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: Image.asset(
                                'resources/images/antony.jpg',
                              ),
                            ),
                          ),
                          onPressed: () {
                            print('Profile');
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            top: screenHeight > 800
                                ? screenHeight * 0.38
                                : screenHeight * 0.285),
                        child: TextButton(
                          child: const Icon(Icons.add),
                          onPressed: () {
                            print('Add');
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: TextButton(
                          child: const Icon(Icons.favorite),
                          onPressed: () {
                            print('Favorite');
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: TextButton(
                          child: const Icon(Icons.text_snippet),
                          onPressed: () {
                            print('Text');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: screenHeight > 800 ? screenHeight * 0.92 : screenHeight * 0.88,
            left: 0,
            child: SizedBox(
              width: screenWidth,
              height: screenHeight * 0.15,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: screenWidth * 0.28,
                        ),
                        Material(
                          color: Colors.transparent,
                          child: SizedBox(
                            width: 28,
                            child: Text(
                              noxifyState.songTimeString,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: screenWidth * 0.48,
                          child: Material(
                            color: Colors.transparent,
                            child: Slider(
                              value: noxifyState.currentSongPosition,
                              onChanged: noxifyState.isSongLoaded
                                  ? (value) {
                                      noxifyState.player.seek(
                                        Duration(
                                          seconds:
                                              (noxifyState.currentSongDuration *
                                                      value)
                                                  .floor(),
                                        ),
                                      );
                                      setState(() {
                                        noxifyState.currentSongPosition = value;
                                      });
                                    }
                                  : null,
                              min: 0.0,
                              max: 1.0,
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: SizedBox(
                            width: 28,
                            child: Text(
                              noxifyState.songDurationString,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: screenWidth > 600
                              ? screenWidth * 0.4
                              : screenWidth * 0.2,
                        ),
                        IconButton(
                          icon: const Icon(Icons.shuffle),
                          color: noxifyState.isShuffle
                              ? Theme.of(context).primaryColor
                              : Colors.white,
                          onPressed: noxifyState.isAlbumLoaded
                              ? () {
                                  noxifyState.toggleShuffle();
                                }
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.loop),
                          color: noxifyState.isLooping
                              ? Theme.of(context).primaryColor
                              : Colors.white,
                          onPressed: () {
                            noxifyState.toggleLooping();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous),
                          color: noxifyState.previousSongs.isNotEmpty
                              ? Colors.white
                              : Colors.white24,
                          onPressed: noxifyState.previousSongs.isNotEmpty
                              ? () {
                                  noxifyState.skipPrevious();
                                }
                              : null,
                        ),
                        if (noxifyState.isSongLoaded)
                          IconButton(
                            icon: Icon(noxifyState.isPlaying
                                ? Icons.pause_sharp
                                : Icons.play_arrow_sharp),
                            onPressed: () {
                              noxifyState.togglePlaying();
                            },
                          ),
                        if (!noxifyState.isSongLoaded)
                          const IconButton(
                            icon: Icon(Icons.play_arrow_sharp),
                            color: Colors.white24,
                            onPressed: null,
                          ),
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          color: noxifyState.nextSongs.isNotEmpty
                              ? Colors.white
                              : Colors.white24,
                          onPressed: noxifyState.nextSongs.isNotEmpty
                              ? () {
                                  noxifyState.skipNext();
                                }
                              : null,
                        ),
                        SizedBox(
                          width: screenWidth * 0.03,
                        ),
                        if (noxifyState.volume == 0.0)
                          const Icon(Icons.volume_off)
                        else if (noxifyState.volume < 0.2)
                          const Icon(Icons.volume_mute)
                        else if (noxifyState.volume < 0.4)
                          const Icon(Icons.volume_down)
                        else
                          const Icon(Icons.volume_up),
                        if (screenWidth > 600)
                          Material(
                            color: Colors.transparent,
                            child: Slider(
                              thumbColor: Colors.white,
                              value: noxifyState.volume,
                              onChanged: (value) {
                                noxifyState.player.setVolume(value);
                                setState(() {
                                  noxifyState.volume = value;
                                });
                              },
                              min: 0.0,
                              max: 1.0,
                            ),
                          ),
                        if (screenWidth > 600)
                          Material(
                            color: Colors.transparent,
                            child: Text(
                              '${(noxifyState.volume * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top:
                screenHeight > 800 ? screenHeight * 0.925 : screenHeight * 0.89,
            left: 10,
            child: Row(
              children: [
                SizedBox(
                  width: screenWidth > 600 ? 100 : screenWidth * 0.15,
                  height: screenWidth > 600 ? 100 : screenWidth * 0.15,
                  child: Container(
                    color: Colors.white,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'resources/images/antony.jpg',
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: screenWidth * 0.02,
                ),
                Material(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      if (screenWidth <= 600)
                        const SizedBox(
                          height: 10,
                        ),
                      Text(
                        noxifyState.currentSong,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth > 600 ? 20 : 12,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          if (screenWidth > 600)
                            Text(
                              noxifyState.currentAlbum,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (screenWidth > 600) const Text(' - '),
                          if (screenWidth > 600)
                            Text(
                              noxifyState.currentArtist,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Home Page'),
        ],
      ),
    );
  }
}

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

// songs.local file:
// id
// title
// artist
// album
//
// id
// title
// artist
// album
//
// ...

class Playlist {
  final int id;
  String title;
  String author;
  List<int> songs;

  Playlist({
    required this.id,
    this.title = '',
    this.author = '',
    this.songs = const [],
  });

  void load(int id) async {
    // load playlist data from file
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
        songs = playlistsData[i + 3].split(',').map(int.parse).toList();
        break;
      }
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

          final noxifyState = Provider.of<NoxifyState>(context);
          final screenHeight = MediaQuery.sizeOf(context).height;
          final screenWidth = MediaQuery.sizeOf(context).width;

          return Center(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: screenHeight * 0.04,
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.center,
                        color: Colors.black54,
                        child: Text(
                          'Local',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth > 600 ? 20 : 10,
                          ),
                        ),
                      ),
                      for (var song in songsLocal)
                        Container(
                          color: Colors.black54,
                          child: ListTile(
                            title: Text(
                              song.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth > 600 ? 20 : 10,
                              ),
                              overflow: TextOverflow.ellipsis,
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
                              noxifyState.loadSong(song);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: screenHeight * 0.04,
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.center,
                        color: Colors.black54,
                        child: Text(
                          'Upstream',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth > 600 ? 20 : 9,
                          ),
                        ),
                      ),
                      for (var song in songsUpstream)
                        Container(
                          color: Colors.black54,
                          child: ListTile(
                            title: Text(
                              song.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth > 600 ? 20 : 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              song.artist,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth > 600 ? 15 : 8,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {},
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: screenHeight * 0.04,
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.center,
                        color: Colors.black54,
                        child: Text(
                          'Playlists',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth > 600 ? 20 : 10,
                          ),
                        ),
                      ),
                      for (var playlist in playlists)
                        Container(
                          color: Colors.black54,
                          child: ListTile(
                            title: Text(
                              playlist.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth > 600 ? 20 : 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              playlist.author,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth > 600 ? 15 : 8,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {},
                          ),
                        ),
                      // fill remaining space
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

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Settings Page'),
        ],
      ),
    );
  }
}

class FoundPage extends StatelessWidget {
  const FoundPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Found Page'),
        ],
      ),
    );
  }
}

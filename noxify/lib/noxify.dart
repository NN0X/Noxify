import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

import 'home.dart';
import 'songs.dart';
import 'playlists.dart';
import 'utils.dart';

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

class NoxifyState extends ChangeNotifier {
  var isDarkMode = true;
  var themeMode = ThemeMode.dark;
  var isNavRail = false;
  var searchQuery = '';
  var switchingSong = false;

  var userID = -1;
  var userName = '';
  var avatarPath = '';

  final player = AudioPlayer();
  var isLooping = false;
  var isAlbumLoaded = false;
  var isShuffle = false;
  var isSongLoaded = false;
  var isPlaying = false;

  Song currentSong = Song(id: -1);
  var currentSongDuration = 0.0;
  var currentSongPosition = 0.0;
  var volume = 0.5;
  var previousSongs = <Song>[];
  var nextSongs = <Song>[];

  var songTimeString = '';
  var songDurationString = '';

  var isSongsFocused = true;
  var isPlaylistsFocused = true;

  void loadUser() async {
    // load user data from file
    String file;
    try {
      file = await rootBundle.loadString('resources/user.local');
    } catch (e) {
      print('Error loading user data');
      return;
    }
    final lines = file.toString().split('\n');
    userID = int.parse(lines[0]);
    userName = lines[1];
    avatarPath = 'resources/avatars/$userID.jpg';
    notifyListeners();
  }

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
      previousSong = previousSongs.removeLast();
      nextSongs.insert(0, currentSong);
      loadSong(previousSong, isAlbumLoaded);
    }
  }

  void skipNext(bool overrideShuffle) {
    Song nextSong;
    if (nextSongs.isNotEmpty) {
      if (isShuffle && !overrideShuffle) {
        final randomIndex = randomInt(0, nextSongs.length);
        nextSong = nextSongs.removeAt(randomIndex);
        previousSongs.add(currentSong);
        loadSong(nextSong, isAlbumLoaded);
      } else {
        nextSong = nextSongs.removeAt(0);
        previousSongs.add(currentSong);
        loadSong(nextSong, isAlbumLoaded);
      }
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

    final songTimeMinutes = (songTime / 60).round();
    final songTimeSeconds = (songTime % 60).round();
    final songDurationMinutes = (currentSongDuration / 60).round();
    final songDurationSeconds = (currentSongDuration % 60).round();

    songTimeString =
        '$songTimeMinutes:${songTimeSeconds.toString().padLeft(2, '0')}';
    songDurationString =
        '$songDurationMinutes:${songDurationSeconds.toString().padLeft(2, '0')}';
    notifyListeners();
  }

  void loadSong(Song song, bool isAlbum) {
    if (isSongLoaded) {
      player.stop();
    }
    currentSong = song;

    loadAudioFile('resources/audio/${song.id}.mp3').then((audioFile) {
      player.play(BytesSource(audioFile));
      switchingSong = false;
    });
    player.setVolume(volume);

    currentSongPosition = 0.0;
    print('Loading song: ${song.id}');
    print('Title: ${song.title}');
    print('Artist: ${song.artist}');
    print('Album: ${song.album}');
    isPlaying = true;
    isSongLoaded = true;
    isAlbumLoaded = isAlbum;
    player.resume();
    notifyListeners();
  }

  loadPlaylist(Playlist playlist) {
    // add to next songs all songs from playlist except the first one
    nextSongs = playlist.songs.sublist(1);
    loadSong(playlist.songs[0], true);
  }
}

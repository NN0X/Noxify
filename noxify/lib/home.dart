import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dart:math';

import 'noxify.dart';
import 'library.dart';
import 'search.dart';
import 'settings.dart';

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
      if (noxifyState.switchingSong) {
        return;
      }
      noxifyState.switchingSong = true;
      if (!noxifyState.isLooping) {
        noxifyState.isPlaying = false;
        noxifyState.player.pause();
        noxifyState.skipNext(false);
      } else {
        noxifyState.player.pause();
        noxifyState.player.seek(const Duration(seconds: 0));
        noxifyState.player.resume();
      }
    });

    noxifyState.loadUser();

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
                              child: noxifyState.userID == -1
                                  ? const Icon(Icons.account_circle)
                                  : Image.asset(noxifyState.avatarPath),
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
                              onChangeStart: (_) {
                                noxifyState.player.pause();
                              },
                              onChangeEnd: (_) {
                                noxifyState.player.resume();
                              },
                              onChanged: noxifyState.isSongLoaded
                                  ? (value) {
                                      noxifyState.player.seek(
                                        Duration(
                                          seconds:
                                              (noxifyState.currentSongDuration *
                                                      value)
                                                  .round(),
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
                          onPressed: noxifyState.nextSongs.isNotEmpty
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
                                  noxifyState.skipNext(false);
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
                                num valueNum = value;
                                valueNum = pow(valueNum, 2);
                                double valueDouble = valueNum.toDouble();
                                // num to double
                                noxifyState.player.setVolume(valueDouble);
                                setState(() {
                                  noxifyState.volume = value;
                                });
                              },
                              min: 0.0,
                              max: 1.0,
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
                      child: noxifyState.isSongLoaded
                          ? Image.asset(
                              'resources/covers/${noxifyState.currentSong.id}.jpg',
                            )
                          : null,
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
                        noxifyState.currentSong.title,
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
                              noxifyState.currentSong.album,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (noxifyState.currentSong.album != '')
                            if (screenWidth > 600) const Text(' | '),
                          if (screenWidth > 600)
                            Text(
                              noxifyState.currentSong.artist,
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

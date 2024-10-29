import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(const Noxify());

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
  var isNavRail = true;
  var searchQuery = '';

  var isSongLoaded = true;
  var isPlaying = false;
  var currentSong = '';
  var currentSongDuration = 0.0;
  var currentSongPosition = 0.0;

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
    notifyListeners();
  }

  void skipPrevious() {
    print('Skip previous');
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
                          width: screenWidth * 0.15,
                          child: NavigationRail(
                            extended: noxifyState.isNavRail,
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
                        height: screenHeight * 0.06,
                        width: double.infinity,
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: screenWidth * 0.015,
                            bottom: screenWidth * 0.02,
                            left: screenWidth * 0.05,
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding:
                                    EdgeInsets.only(top: screenWidth * 0.01),
                                child: SizedBox(
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
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: screenWidth * 0.15,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.006),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            shape: const CircleBorder(),
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(Icons.person),
                          ),
                          onPressed: () {
                            print('Profile');
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.285),
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
            top: screenHeight * 0.9,
            left: 0,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  color:
                      noxifyState.isSongLoaded ? Colors.white : Colors.white24,
                  onPressed: () {
                    noxifyState.skipPrevious();
                  },
                ),
                IconButton(
                  icon: Icon(noxifyState.isPlaying
                      ? Icons.pause_sharp
                      : Icons.play_arrow_sharp),
                  onPressed: () {
                    noxifyState.togglePlaying();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  color:
                      noxifyState.isSongLoaded ? Colors.white : Colors.white24,
                  onPressed: () {
                    print('Skip next');
                  },
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

class LibraryPage extends StatelessWidget {
  const LibraryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Library Page'),
        ],
      ),
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

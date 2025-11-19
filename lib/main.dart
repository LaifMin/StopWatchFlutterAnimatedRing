import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StopWatch app',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2D5F3F),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF3D8B5C),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const MyHomePage(title: 'StopWatch App'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _StopWatchState();
}

class _StopWatchState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  // Stopwatch flags 
  String _cronoString = "00:00.00"; // base String
  bool isRunning = false; // if countring --> true
  bool nextState = false; //  true if started
  bool nextStateButtns = false; // true if paused
  
  late Stream<int> time; // dumping 1 int into tickerFraction every 10 milli
  late Stream<int> tickerFraction;
  late StreamSubscription<int> tickerSubscription; // subscription to the stream, needed to cancel, pause or resume
  
  int ticks = 0;
  int milliseconds = 0;
  int seconds = 0;
  int minutes = 0;
  int trotation = 500; // var to set the rotation time of the animated border
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: trotation), // to complete a full rotation trotation
    );
  }

  @override
  void dispose() {
    // memory leaks problem if not disposed
    _animationController.dispose();
    super.dispose();
  }

  void _startingCrono() {
    time = Stream.periodic(const Duration(milliseconds: 10), (x) => x); // keeps emitting ints every 10 milliseconds
    tickerFraction = time.map((tick) => tick);
    tickerSubscription = tickerFraction.listen((tick) {
      if (isRunning) {
        ticks++;
        updateState(ticks);
      }
    });
  }

  void updateState(int tick) {
    setState(() {
      String mm = "00";
      String ss = "00";
      String ms = "00";

      int currentTicks = tick % 100;
      
      if (tick > 0 && tick % 100 == 0) {
        seconds++;
      }

      ms = currentTicks < 10 ? "0$currentTicks" : "$currentTicks";

      if (seconds >= 60) {
        minutes++;
        seconds = 0;
      }

      ss = seconds < 10 ? "0$seconds" : "$seconds";
      mm = minutes < 10 ? "0$minutes" : "$minutes";

      if (minutes >= 99) {
        minutes = 0;
        seconds = 0;
        ticks = 0;
      }

      _cronoString = "$mm:$ss.$ms";
    });
  }

  void dump() {  // destroyes the stream subscription and resets all values
    tickerSubscription.cancel();
    minutes = 0;
    seconds = 0;
    milliseconds = 0;
  }

  void cronoPause() {
    setState(() {
      isRunning = !isRunning; // if true --> false , if false --> true
      if (isRunning) {
        _animationController.repeat(); // looping animation
      } else {
        _animationController.stop();
      }
    });
  }

  Widget body() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _animationController, // this goes from 0.0 to 1.0 over the duration
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _animationController.value * 2 * math.pi, // full rotation
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              const Color(0xFF4CAF50),
                              const Color(0xFF3D8B5C),
                              const Color(0xFF2D5F3F),
                              Colors.transparent,
                              Colors.transparent,
                              const Color(0xFF2D5F3F),
                              const Color(0xFF3D8B5C),
                              const Color(0xFF4CAF50),
                            ],
                            stops: const [0.0, 0.1, 0.2, 0.3, 0.7, 0.8, 0.9, 1.0],  // every color 'stop' defines where the color is fully applied
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3D8B5C).withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: 264,
                  height: 264,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  child: Center(
                    child: Text(
                      _cronoString, // stopwatch string and its values
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buttonAction() {
    if (!nextState) { // initial state (never started)
      return TextButton(
        style: TextButton.styleFrom(
          side: const BorderSide(color: Color(0xFF3D8B5C), width: 2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        ),
        onPressed: () => setState(() {
        _startingCrono(); // stream activated
        nextState = true; // now started 
        isRunning = true; // now counting (not the same thing as  'now started')
        _animationController.repeat(); // start the animation
        }),
        child: const Text(
          "start",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      if (nextStateButtns) { // puased logic
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              style: TextButton.styleFrom(
                side: const BorderSide(color: Color(0xFF3D8B5C), width: 2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              onPressed: () => setState(() {
                //stop logic everything to 0 and dump the stream
                dump();
                isRunning = false;
                nextState = false;
                nextStateButtns = false;
                ticks = 0;
                seconds = 0;
                minutes = 0;
                _cronoString = "00:00.00";
                _animationController.reset();
              }),
              child: const Text(
                "stop",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 30),
            TextButton(
              style: TextButton.styleFrom(
                side: const BorderSide(color: Color(0xFF3D8B5C), width: 2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              onPressed: () => setState(() {
                // continue logic
                cronoPause();
                nextStateButtns = false;
              }),
              child: const Text(
                "continue",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      } else {
        return TextButton(
          style: TextButton.styleFrom(
            side: const BorderSide(color: Color(0xFF3D8B5C), width: 2),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          ),
          onPressed: () => setState(() {
            // pause logic
            cronoPause();
            nextStateButtns = true;
          }),
          child: const Text(
            "pause",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 60),
            body(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buttonAction(),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Container(
      decoration: const BoxDecoration(
      border: Border(
      top: BorderSide(
      color: Color.fromARGB(255, 56, 56, 56),
      width: 1,
      ),
      ),
      ),
      child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
      Text(
      "developing tool",
      style: TextStyle(
        color: Colors.white70,
          fontSize: 14,
            fontWeight: FontWeight.w400,
            ),
            ),
        ],
      ),
    ),
    );
  }
}

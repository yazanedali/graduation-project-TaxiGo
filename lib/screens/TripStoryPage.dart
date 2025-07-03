import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taxi Memories',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: TripStoryPage(
        startLocation: 'Downtown Mall',
        endLocation: 'Tech Park',
        tripTime: DateTime.now(),
        distance: 8.5,
        driverName: 'Ahmed Mohamed',
        carModel: 'Toyota Camry 2022',
        rating: 4.7,
        comment: 'Great conversation about local tech scene!',
        imageUrl: 'https://example.com/trip_photo.jpg',
      ),
    );
  }
}

class TripStoryPage extends StatefulWidget {
  final String startLocation;
  final String endLocation;
  final DateTime tripTime;
  final double distance;
  final String driverName;
  final String carModel;
  final double rating;
  final String? comment;
  final String? imageUrl;

  const TripStoryPage({
    required this.startLocation,
    required this.endLocation,
    required this.tripTime,
    required this.distance,
    required this.driverName,
    required this.carModel,
    required this.rating,
    this.comment,
    this.imageUrl,
    super.key,
  });

  @override
  State<TripStoryPage> createState() => _TripStoryPageState();
}

class _TripStoryPageState extends State<TripStoryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showDetails = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _shareTrip() {
    final String shareText =
        'My taxi trip from ${widget.startLocation} to ${widget.endLocation} '
        'was amazing! ${widget.distance} km in ${DateFormat.jm().format(widget.tripTime)} '
        'with rating ${widget.rating}/5 ⭐️';

    Share.share(shareText, subject: 'Check out my taxi trip!');
  }

  void _toggleSave() {
    setState(() {
      _isSaved = !_isSaved;
      if (_isSaved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip saved to your memories!')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showDetails = !_showDetails),
        child: Stack(
          children: [
            // Background
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: widget.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(widget.imageUrl!),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          const Color.fromRGBO(0, 0, 0, 0.4),
                          BlendMode.darken,
                        ),
                      )
                    : null,
                gradient: widget.imageUrl == null
                    ? const LinearGradient(
                        colors: [Colors.blueAccent, Colors.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
            ),

            // Route Animation
            Positioned(
              top: size.height * 0.2,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: RoutePainter(
                      progress: _controller.value,
                      startLocation: widget.startLocation,
                      endLocation: widget.endLocation,
                    ),
                  );
                },
              ),
            ),

            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        if (_showDetails)
                          Text(
                            'Trip Memories',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const Spacer(),
                    if (_showDetails) ...[
                      TripDetailCard(
                        icon: Icons.person,
                        title: 'Your Driver',
                        value: widget.driverName,
                        rating: widget.rating,
                      ),
                      TripDetailCard(
                        icon: Icons.directions_car,
                        title: 'Vehicle',
                        value: widget.carModel,
                      ),
                      TripDetailCard(
                        icon: Icons.attach_money,
                        title: 'Fare',
                        value: '${(widget.distance * 1.5).toStringAsFixed(2)} AED',
                      ),
                      const SizedBox(height: 20),
                    ],
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _showDetails
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InfoRow(
                                  icon: Icons.location_on,
                                  label: 'From',
                                  value: widget.startLocation,
                                ),
                                InfoRow(
                                  icon: Icons.flag,
                                  label: 'To',
                                  value: widget.endLocation,
                                ),
                                InfoRow(
                                  icon: Icons.schedule,
                                  label: 'When',
                                  value: DateFormat('MMM d, y • h:mm a').format(widget.tripTime),
                                ),
                                InfoRow(
                                  icon: Icons.route,
                                  label: 'Distance',
                                  value: '${widget.distance.toStringAsFixed(1)} km',
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Trip Story',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      const Shadow(
                                        blurRadius: 10,
                                        color: Colors.black54,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${widget.startLocation} → ${widget.endLocation}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    if (widget.comment != null && _showDetails)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.comment, color: Colors.white70),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.comment!,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (_showDetails)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ActionButton(
                            icon: Icons.share,
                            label: 'Share',
                            onPressed: _shareTrip,
                          ),
                          ActionButton(
                            icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                            label: _isSaved ? 'Saved' : 'Save',
                            onPressed: _toggleSave,
                          ),
                          ActionButton(
                            icon: Icons.star,
                            label: 'Rate',
                            onPressed: () {},
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoutePainter extends CustomPainter {
  final double progress;
  final String startLocation;
  final String endLocation;

  RoutePainter({
    required this.progress,
    required this.startLocation,
    required this.endLocation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.5,
        size.width * 0.8,
        size.height * 0.1,
      );

    final animatedPath = Path();
    for (final metric in path.computeMetrics()) {
      animatedPath.addPath(
        metric.extractPath(0, metric.length * progress),
        Offset.zero,
      );
    }

    canvas.drawPath(animatedPath, paint);

    if (progress > 0.3) {
      canvas.drawCircle(
        Offset(size.width * 0.2, size.height * 0.2),
        8,
        Paint()..color = Colors.green,
      );
    }
    if (progress > 0.8) {
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.1),
        8,
        Paint()..color = Colors.red,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TripDetailCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final double? rating;

  const TripDetailCard({
    required this.icon,
    required this.title,
    required this.value,
    this.rating,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white70),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(color: Colors.white),
        ),
        trailing: rating != null
            ? Text('${rating!.toStringAsFixed(1)} ⭐', style: const TextStyle(color: Colors.amber))
            : null,
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.white70)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          color: Colors.white,
          onPressed: onPressed,
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:agrismart/core/database/db_helper.dart';
import 'package:agrismart/core/network/weather_service.dart';
import 'package:agrismart/features/auth/presentation/pages/login_screen.dart';

const String baseUrl = "http://192.168.1.87:8000";

class Dashboard extends StatefulWidget {
  final String userEmail; 
  const Dashboard({super.key, required this.userEmail});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  String? _capturedImagePath;
  
  double _liveTemperature = 27.2;
  double _liveHumidity = 68.0;

  void _handleImageAnalysisRouting(String imagePath) {
    setState(() {
      _capturedImagePath = imagePath;
      _selectedIndex = 2; // Route straight to Analyze View
    });
  }

  void _updateLiveEnvironmentMetrics(double temp, double humidity) {
    setState(() {
      _liveTemperature = temp;
      _liveHumidity = humidity;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardScreen(
        onProfileClicked: () => setState(() => _selectedIndex = 4),
        onWeatherLoaded: _updateLiveEnvironmentMetrics,
      ),
      CameraScreen(onImageSelected: _handleImageAnalysisRouting, isCurrentTab: _selectedIndex == 1), 
      AnalyzeScreen(
        imagePath: _capturedImagePath,
        initialTemp: _liveTemperature,
        initialHumidity: _liveHumidity,
      ), 
      const HistoryScreen(),
      ProfileScreen(
        userEmail : widget.userEmail,
        onLoggedOut: () {
        setState(() {
          _capturedImagePath = null;
          _selectedIndex = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session closed. User logged out securely.")),
        );
      }),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: _selectedIndex == 4 
          ? null 
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF1B5E20),
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Home"),
                BottomNavigationBarItem(icon: Icon(Icons.camera_alt_outlined), activeIcon: Icon(Icons.camera_alt), label: "Scan"),
                BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: "Analyze"),
                BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: "History"),
              ],
            ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final VoidCallback onProfileClicked;
  final Function(double, double) onWeatherLoaded;
  
  const DashboardScreen({super.key, required this.onProfileClicked, required this.onWeatherLoaded});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _weatherData = {
    'location': 'Bharatpur, Nepal',
    'temp': '28.0°C',
    'wind': '12 km/h',
    'isLoaded': true
  };

  @override
  void initState() {
    super.initState();
    _initDashboardMetrics();
  }

  Future<void> _initDashboardMetrics() async {
    try {
      final liveWeather = await WeatherService().fetchLocalWeather();
      if (mounted) {
        setState(() => _weatherData = liveWeather);
        final double parsedTemp = double.parse(liveWeather['temp'].replaceAll('°C', '').trim());
        widget.onWeatherLoaded(parsedTemp, 68.0);
      }
    } catch (_) {}
  }

  // Helper method to show quick utility tool dialogs 🛠️
  void _showUtilityDialog(String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1B5E20))),
        content: Text(description, style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Color(0xFF1B5E20))),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("AgriSmart Dashboard", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: widget.onProfileClicked, 
            icon: const Icon(Icons.account_circle, color: Colors.white, size: 28),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _initDashboardMetrics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Weather & Smart Field Advisory 🌤️
              _buildWeatherSection(),
              const SizedBox(height: 24),

              // Section 2: Interactive Essential Utilities ⚡
              Text("Essential Utility Tools", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildFarmerUtilityGrid(),
              const SizedBox(height: 24),

              // Section 3: Live Mandi Index 📈
              Text("Local Mandi Indexes", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildMandiPriceIndexCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, const Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(_weatherData['location'], style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(_weatherData['temp'], style: GoogleFonts.poppins(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                  Text("Wind: ${_weatherData['wind']}", style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontStyle: FontStyle.italic)),
                ],
              ),
              const Icon(Icons.wb_sunny, color: Colors.amber, size: 60),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          
          // Actionable Field Advisory 💡
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.amberAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Advisory: Clear skies expected. Favorable conditions for foliar spray and field inspection.",
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerUtilityGrid() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      children: [
        _buildUtilityItemCard("Seed Calculator", Icons.calculate_outlined, Colors.teal, () {
          _showUtilityDialog("Seed Rate Calculator 🧮", "Enter field area (in Bigha/Kattha or Acres) to estimate seed quantity required for Paddy, Tomato, or Wheat.");
        }),
        _buildUtilityItemCard("Crop Advisory", Icons.gavel_outlined, Colors.orange, () {
          _showUtilityDialog("Crop Advisory 🌾", "Get seasonal crop rotation guidelines and recommended planting dates for local climate conditions.");
        }),
        _buildUtilityItemCard("Fertilizer Mixer", Icons.science_outlined, Colors.blue, () {
          _showUtilityDialog("Fertilizer Calculator 🧪", "Calculate balanced N-P-K ratios based on target crop requirement and soil type.");
        }),
        _buildUtilityItemCard("Subsidies Guide", Icons.monetization_on_outlined, Colors.purple, () {
          _showUtilityDialog("Government Subsidies 🏛️", "View active agricultural equipment and seed subsidy programs available in your local district.");
        }),
      ],
    );
  }

  Widget _buildUtilityItemCard(String label, IconData icon, Color designTheme, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: designTheme.withOpacity(0.1), child: Icon(icon, color: designTheme, size: 20)),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87))),
          ],
        ),
      ),
    );
  }

  Widget _buildMandiPriceIndexCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildMarketRowItem("Tomato (Local)", " NPR 45 / Kg", true),
          const Divider(height: 16),
          _buildMarketRowItem("Onion (Dry)", " NPR 62 / Kg", false),
          const Divider(height: 16),
          _buildMarketRowItem("Ginger", " NPR 110 / Kg", true),
        ],
      ),
    );
  }

  Widget _buildMarketRowItem(String itemTitle, String currentPrice, bool isIncreasing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(itemTitle, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        Row(
          children: [
            Text(currentPrice, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Icon(
              isIncreasing ? Icons.trending_up : Icons.trending_down,
              color: isIncreasing ? Colors.green : Colors.red,
              size: 16,
            )
          ],
        )
      ],
    );
  }
}
// ============================================================================
// 2. CAMERA VIEWFINDER CONTEXT
// ============================================================================
class CameraScreen extends StatefulWidget {
  final Function(String) onImageSelected;
  final bool isCurrentTab;
  
  const CameraScreen({super.key, required this.onImageSelected, required this.isCurrentTab});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraInitialized = false;

  @override
  void didUpdateWidget(covariant CameraScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentTab && !oldWidget.isCurrentTab) {
      _initializeCamera();
    } else if (!widget.isCurrentTab && oldWidget.isCurrentTab) {
      _deconstructCameraSession();
    }
  }

  Future<void> _initializeCamera() async {
    if (_isCameraInitialized) return;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(backCamera, ResolutionPreset.medium, enableAudio: false);
      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;
      
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  void _deconstructCameraSession() {
    _controller?.dispose();
    _controller = null;
    _isCameraInitialized = false;
  }

  @override
  void dispose() {
    _deconstructCameraSession();
    super.dispose();
  }

  void _showPreviewDialog(String imagePath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Confirm Captured Leaf", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1B5E20))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(imagePath), height: 180, width: 180, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
              Text("Process leaf scan through AgriSmart AI backend?", textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Retake", style: TextStyle(color: Colors.red))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(dialogContext);
                widget.onImageSelected(imagePath);
              },
              child: const Text("Analyze"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20))));
    }

    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Positioned.fill(child: CameraPreview(_controller!)),
                Center(
                  child: Container(
                    width: 240, height: 240,
                    decoration: BoxDecoration(border: Border.all(color: Colors.green, width: 3), borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1B5E20),
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller!.takePicture();
            if (mounted) _showPreviewDialog(image.path);
          } catch (e) {
            debugPrint(e.toString());
          }
        },
        child: const Icon(Icons.camera, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ============================================================================
// 3. COMPLETE ANALYZE SCREEN WITH LEAF SCAN & SOIL METRICS
// ============================================================================
class AnalyzeScreen extends StatefulWidget {
  final String? imagePath;
  final double initialTemp;
  final double initialHumidity;

  const AnalyzeScreen({
    super.key,
    this.imagePath,
    required this.initialTemp,
    required this.initialHumidity,
  });

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  String? _plantName;
  String? _condition;
  double _confidence = 0.0;
  String? _medicine;
  String? _prevention;

  @override
  void initState() {
    super.initState();
    _executeComprehensiveAnalysis();
  }

  @override
  void didUpdateWidget(covariant AnalyzeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imagePath != oldWidget.imagePath) {
      _executeComprehensiveAnalysis();
    }
  }

  Future<void> _executeComprehensiveAnalysis() async {
    if (widget.imagePath == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final leafUri = Uri.parse('$baseUrl/api/diagnose-leaf');
      var request = http.MultipartRequest('POST', leafUri);
      request.files.add(await http.MultipartFile.fromPath('file', widget.imagePath!));

      var streamedResponse = await request.send();
      var leafResponse = await http.Response.fromStream(streamedResponse);

      if (leafResponse.statusCode == 200) {
        final leafData = jsonDecode(leafResponse.body);
        setState(() {
          _plantName = leafData['plant_name'];
          _condition = leafData['condition'];
          _confidence = (leafData['confidence_percentage'] as num).toDouble();
          _medicine = leafData['medicine_recommendation'];
          _prevention = leafData['prevention'];
        });

        // Save scan automatically to SQLite History 💾
        await DBHelper().insertData('disease_history', {
          'plant_name': _plantName,
          'disease_name': _condition,
          'confidence': _confidence,
          'medicine': _medicine,
          'prevention': _prevention,
          'image_path': widget.imagePath,
          'date': DateTime.now().toString().substring(0, 10),
        });
      } else {
        setState(() {
          _errorMessage = "Server error (${leafResponse.statusCode}). Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Unable to connect to backend server: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Agronomic Diagnostics", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B5E20),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.red.shade800, fontSize: 13)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                          onPressed: _executeComprehensiveAnalysis,
                          child: const Text("Retry Analysis", style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Captured Image Header 📸
                      if (widget.imagePath != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(File(widget.imagePath!), height: 200, width: double.infinity, fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Diagnostic Results 📑
                      _buildReportCard(
                        title: "Identified Plant Host 🌿",
                        content: _plantName ?? "Awaiting Leaf Scan",
                        icon: Icons.eco,
                        color: Colors.green.shade800,
                      ),
                      const SizedBox(height: 12),

                      _buildReportCard(
                        title: "Disease Diagnostics Report 🔬",
                        content: _condition != null ? "$_condition (${_confidence.toStringAsFixed(1)}% Confidence)" : "No scan submitted.",
                        icon: Icons.bug_report,
                        color: Colors.orange.shade900,
                      ),
                      const SizedBox(height: 12),

                      _buildReportCard(
                        title: "Treatment & Medicine Plan 💊",
                        content: _medicine ?? "No prescription required.",
                        icon: Icons.medication,
                        color: Colors.blue.shade900,
                      ),
                      const SizedBox(height: 12),

                      _buildReportCard(
                        title: "Prevention Guidelines 🛡️",
                        content: _prevention ?? "Maintain general field cleanliness.",
                        icon: Icons.shield,
                        color: Colors.purple.shade900,
                      ),
                      const SizedBox(height: 20),

                      // Environmental Metrics Summary 🌡️
                      Text("Field Environmental Snapshot", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text("Temperature: ${widget.initialTemp}°C", style: GoogleFonts.poppins(fontSize: 12)),
                            Text("Humidity: ${widget.initialHumidity}%", style: GoogleFonts.poppins(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildReportCard({required String title, required String content, required IconData icon, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(content, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Scan History Logs", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1B5E20),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DBHelper().getData('disease_history'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.isEmpty) {
            return Center(child: Text("No scans recorded yet.", style: GoogleFonts.poppins(color: Colors.grey)));
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              final imagePath = item['image_path'];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ExpansionTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imagePath != null && File(imagePath).existsSync()
                        ? Image.file(File(imagePath), width: 50, height: 50, fit: BoxFit.cover)
                        : const Icon(Icons.eco, color: Color(0xFF1B5E20), size: 40),
                  ),
                  title: Text(
                    "${item['plant_name'] ?? 'Crop'} - ${item['disease_name']}", 
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)
                  ),
                  subtitle: Text("Date: ${item['date']} • Confidence: ${item['confidence']}%", style: GoogleFonts.poppins(fontSize: 11)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Rx / Treatment:", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue.shade900)),
                          Text(item['medicine'] ?? 'N/A', style: GoogleFonts.poppins(fontSize: 12)),
                          const SizedBox(height: 8),
                          Text("Prevention:", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.purple.shade900)),
                          Text(item['prevention'] ?? 'N/A', style: GoogleFonts.poppins(fontSize: 12)),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
class ProfileScreen extends StatefulWidget {
  final String userEmail; // Pass the logged-in user's email or identifier
  final VoidCallback onLoggedOut;

  const ProfileScreen({
    super.key, 
    required this.userEmail, 
    required this.onLoggedOut,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // 1. Fetch user record from SQLite using email
  Future<void> _fetchUserProfile() async {
    // Query the user table by email
    final db = await DBHelper().database;
    List<Map<String, dynamic>> results = await db.query(
      'user',
      where: 'email = ?',
      whereArgs: [widget.userEmail],
    );

    if (mounted) {
      setState(() {
        if (results.isNotEmpty) {
          _userData = results.first;
        }
        _isLoading = false;
      });
    }
  }

  // 2. Clear navigation and logout
  void _handleLogout() {
    // Perform any custom logout logic passed from parent
    widget.onLoggedOut();

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final name = _userData?['name'] ?? 'Farmer';
    final location = _userData?['location'] ?? 'Not Set';
    final phone = _userData?['phone'] ?? 'Not Set';

    return Scaffold(
      appBar: AppBar(
        title: Text("Farmer Account Profile", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B5E20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), 
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Center(
              child: CircleAvatar(
                radius: 50, 
                backgroundColor: Color(0xFF1B5E20), 
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(name, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(location, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
            const Divider(height: 40),
            
            // Dynamic Fields from SQLite

            _buildProfileEditableField("Location Context", location),
            _buildProfileEditableField("Mobile Identifier", phone),
            _buildProfileEditableField("Email Address", widget.userEmail),
            
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800, 
                  padding: const EdgeInsets.symmetric(vertical: 14), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _handleLogout,
                child: Text("Terminate Session & Log Out", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileEditableField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
          Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}
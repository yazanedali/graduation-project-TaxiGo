import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حالة الطرق والحواجز',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        fontFamily: 'Tajawal',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Color(0xFFF7F9FC),
        cardColor: Colors.white,
        colorScheme: ColorScheme.light(
          primary: Colors.amber[700]!,
          secondary: Colors.amber[500]!,
          surface: Colors.white,
          onSurface: Colors.black87,
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.amber,
        fontFamily: 'Tajawal',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF121212),
        cardColor: Color(0xFF1E1E1E),
        colorScheme: ColorScheme.dark(
          primary: Colors.amber[400]!,
          secondary: Colors.amber[300]!,
          surface: Color(0xFF1E1E1E),
          onSurface: Colors.white,
        ),
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: RoadStatusScreen(),
    );
  }
}

class RoadStatusScreen extends StatefulWidget {
  @override
  _RoadStatusScreenState createState() => _RoadStatusScreenState();
}

class _RoadStatusScreenState extends State<RoadStatusScreen> {
  String? selectedCity;
  bool isLoading = false;
  String lastUpdated = '';
  // هذا الـ Map سيحتوي على بيانات جميع المدن التي تم تحليلها بواسطة الـ AI
  Map<String, Map<String, Map<String, dynamic>>> allCitiesRoadsData = {};
  String? errorMessage;
  Timer? _refreshTimer;

  // **** هام جداً: لا تضع مفاتيح API السرية مباشرة في كود العميل في تطبيقات الإنتاج! ****
  // **** يجب أن يتم تمرير هذا المفتاح من خلال خادم خلفي (Backend) آمن.           ****
  // **** استبدل 'YOUR_GEMINI_API_KEY' بمفتاح API الخاص بك من Google AI Studio    ****
  final String geminiApiKey = 'AIzaSyCtLX5emoUK2RwchBsXpYuLFsu3jAHSHSc';
  final String botToken =
      '7608922442:AAHaWNXgfJFxgPBi2VJgdWekfznFIQ-4ZOQ'; // هذا للتلغرام، يمكن أن يبقى
  final List<String> availableCities = [
    "نابلس",
    "سلفيت",
    "رام الله",
    "الخليل",
    "بيت لحم"
  ];

  @override
  void initState() {
    super.initState();
    selectedCity = availableCities.first;
    // عند بدء التطبيق، جلب البيانات لجميع المدن
    fetchAllDataFromTelegramBot();

    // التحديث التلقائي كل 5 دقائق
    _refreshTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      fetchAllDataFromTelegramBot();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // هذه الدالة الجديدة ستكون مسؤولة عن جلب ومعالجة جميع الرسائل وتوزيعها على المدن
  Future<void> fetchAllDataFromTelegramBot() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http
          .get(Uri.parse('https://api.telegram.org/bot$botToken/getUpdates'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          final messages = data['result'] as List<dynamic>;

          // تهيئة خريطة مؤقتة لتخزين البيانات الجديدة لجميع المدن
          // سيتم مسح البيانات القديمة بالكامل واستبدالها بالجديدة
          Map<String, Map<String, Map<String, dynamic>>> tempAllCitiesData = {};
          for (var city in availableCities) {
            tempAllCitiesData[city] = {}; // تهيئة كل مدينة بماب فارغ
          }

          List<Future<void>> processingTasks = [];

          // لمعالجة آخر عدد محدود من الرسائل لتجنب تجاوز حدود Gemini API المجانية
          final int messagesToProcessCount = 20; // يمكنك تعديل هذا الرقم
          final int startIndex = messages.length > messagesToProcessCount
              ? messages.length - messagesToProcessCount
              : 0;

          for (int i = startIndex; i < messages.length; i++) {
            var msg = messages[i];
            final text = msg['message']?['text']?.toString();
            final int? messageDate = msg['message']?['date'];

            if (text == null || messageDate == null) continue;

            // فلترة أولية للرسائل غير المتعلقة بأي من المدن أو الطرق بشكل عام
            if (!_isMessagePotentiallyRelevant(text)) continue;

            processingTasks.add(_processTelegramMessageWithAI(
                text, messageDate, tempAllCitiesData));
          }

          // انتظر حتى تكتمل جميع مهام معالجة الـ AI
          await Future.wait(processingTasks);

          setState(() {
            allCitiesRoadsData = tempAllCitiesData; // تحديث البيانات الشاملة
            lastUpdated =
                'آخر تحديث: ${DateFormat('h:mm a', 'ar').format(DateTime.now())}';
          });
        } else {
          throw Exception(
              'استجابة غير صحيحة من سيرفر التلغرام: ${data['description']}');
        }
      } else {
        throw Exception(
            'فشل في الاتصال بسيرفر التلغرام: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage =
            'حدث خطأ في جلب البيانات: ${e.toString().replaceAll(RegExp(r'^Exception: '), '')}';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  // **** هذه هي الدالة التي تستخدم الـ AI (عبر Gemini Pro API) ****
  // تم تعديلها لتستقبل خريطة البيانات الشاملة (allCitiesRoadsData)
  // وتضيف إليها المعلومات مع تحديد المدينة
  Future<void> _processTelegramMessageWithAI(
      String messageText,
      int messageDate,
      Map<String, Map<String, Map<String, dynamic>>> allRoadsData) async {
    if (geminiApiKey == 'YOUR_GEMINI_API_KEY' || geminiApiKey.isEmpty) {
      debugPrint(
          'Gemini API Key is not set or is default. Skipping AI processing.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$geminiApiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "contents": [
            {
              "parts": [
                {
                  "text": """
              أنت مساعد ذكاء اصطناعي يقوم بتحليل رسائل واتساب/تلغرام حول حالة الطرق والحواجز في فلسطين.
              مهمتك هي استخلاص أسماء الطرق/الحواجز وحالتها والمحافظة التي تقع فيها.
              المحافظات المتاحة هي: ${availableCities.join(', ')}.
              الحالات الممكنة هي: 'مفتوح', 'مغلق', 'مزدحم'.
              إذا كانت الرسالة تحتوي على معلومات حول طريق أو حاجز وحالته والمحافظة، قم باستخراج اسم الطريق وحالته والمحافظة.
              إذا لم تُذكر المحافظة بشكل صريح ولكن يمكن استنتاجها من سياق اسم الطريق أو الحاجز، قم بتحديدها.
              إذا كانت الرسالة تشير إلى عدة طرق، قم بإدراجها جميعاً.
              إذا لم يتم العثور على معلومات ذات صلة بحالة طريق، أعد قائمة فارغة [].
              
              أعد الإخراج في تنسيق JSON كقائمة (array) من الكائنات. كل كائن في القائمة يجب أن يحتوي على ثلاثة مفاتيح: 'road_name' (سلسلة نصية), 'status' (سلسلة نصية من الحالات المذكورة أعلاه), و 'city' (سلسلة نصية من قائمة المحافظات المتاحة).
              إذا لم يتم العثور على أي حالة طريق ذات صلة، أعد قائمة فارغة [].
              
              أمثلة:
              الرسالة: 'طريق نابلس-رام الله مفتوح الان'
              الإخراج: [{"road_name": "طريق نابلس-رام الله", "status": "مفتوح", "city": "نابلس"}]

              الرسالة: 'حاجز حوارة مغلق تماماً'
              الإخراج: [{"road_name": "حاجز حوارة", "status": "مغلق", "city": "نابلس"}]

              الرسالة: 'ازمة خانقة عند مدخل الخليل الجنوبي'
              الإخراج: [{"road_name": "مدخل الخليل الجنوبي", "status": "مزدحم", "city": "الخليل"}]
              
              الرسالة: 'صباح الخير يا شباب!'
              الإخراج: []

              الرسالة: 'الطريق المؤدية الى بيت لحم من القدس فيها ازمة شديدة. طريق واد النار مفتوح.'
              الإخراج: [{"road_name": "الطريق المؤدية الى بيت لحم من القدس", "status": "مزدحم", "city": "بيت لحم"}, {"road_name": "واد النار", "status": "مفتوح", "city": "نابلس"}]
              """
                },
                {"text": "الرسالة: '$messageText'"}
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.0,
            "topK": 1,
            "topP": 1,
          },
        }),
      );

      if (response.statusCode == 200) {
        final aiResponse = json.decode(response.body);
        String? content;

        // تحليل استجابة Gemini
        if (aiResponse.containsKey('candidates') &&
            aiResponse['candidates'] is List &&
            (aiResponse['candidates'] as List).isNotEmpty &&
            aiResponse['candidates'][0].containsKey('content') &&
            aiResponse['candidates'][0]['content'].containsKey('parts') &&
            aiResponse['candidates'][0]['content']['parts'] is List &&
            (aiResponse['candidates'][0]['content']['parts'] as List)
                .isNotEmpty &&
            aiResponse['candidates'][0]['content']['parts'][0]
                .containsKey('text')) {
          content = aiResponse['candidates'][0]['content']['parts'][0]['text'];
        } else {
          debugPrint(
              'Unexpected Gemini response structure or missing content: $aiResponse');
          if (aiResponse.containsKey('promptFeedback') &&
              aiResponse['promptFeedback']['blockReason'] != null) {
            debugPrint(
                'Gemini blocked content: ${aiResponse['promptFeedback']['blockReason']}');
          }
          if (aiResponse.containsKey('error')) {
            debugPrint('Gemini API Error: ${aiResponse['error']['message']}');
          }
          return;
        }

        if (content == null || content.trim().isEmpty) {
          debugPrint(
              'Gemini returned empty or null content for message: $messageText');
          return;
        }

        // إزالة علامات Markdown
        String cleanContent = content.trim();
        debugPrint('Raw content from Gemini: $content');
        if (cleanContent.startsWith('```json')) {
          cleanContent = cleanContent.substring(7).trim();
        }
        if (cleanContent.endsWith('```')) {
          cleanContent =
              cleanContent.substring(0, cleanContent.length - 3).trim();
        }
        debugPrint('Cleaned content for JSON parsing: $cleanContent');

        // محاولة تحليل الـ JSON المستخرج من الـ AI
        List<dynamic> extractedRoads;
        try {
          extractedRoads = json.decode(cleanContent);
        } catch (e) {
          debugPrint(
              'Failed to parse AI JSON content from Gemini: $cleanContent, Error: $e');
          return;
        }

        if (extractedRoads is List) {
          for (var roadInfo in extractedRoads) {
            if (roadInfo is Map<String, dynamic> &&
                roadInfo.containsKey('road_name') &&
                roadInfo.containsKey('status') &&
                roadInfo.containsKey('city')) {
              // **** التحقق من وجود مفتاح 'city' الجديد ****
              final roadName = roadInfo['road_name'] as String;
              final status = roadInfo['status'] as String;
              final city =
                  roadInfo['city'] as String; // **** استخراج المدينة ****

              // التأكد من أن اسم الطريق ليس فارغًا، الحالة صحيحة، والمدينة موجودة في قائمتنا
              if (roadName.isNotEmpty &&
                  ['مفتوح', 'مغلق', 'مزدحم'].contains(status) &&
                  availableCities.contains(city)) {
                // **** التأكد من أن المدينة معروفة لدينا ****

                // تحديث البيانات في الخريطة الشاملة (allRoadsData) حسب المدينة الصحيحة
                // مع الأخذ في الاعتبار الرسالة الأحدث
                if (!allRoadsData.containsKey(city)) {
                  allRoadsData[city] =
                      {}; // إذا كانت هذه أول معلومات لهذه المدينة
                }
                if (!allRoadsData[city]!.containsKey(roadName) ||
                    (allRoadsData[city]![roadName]!['date'] as int) <
                        messageDate) {
                  allRoadsData[city]![roadName] = {
                    "name": roadName,
                    "status": status,
                    "date": messageDate,
                    "original_message_text":
                        messageText // إضافة الرسالة الأصلية للمراجعة
                  };
                }
              }
            }
          }
        }
      } else {
        debugPrint(
            'Failed to call Gemini API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error processing message with AI: $e');
    }
  }

  // هذه الدالة الجديدة للفلترة المسبقة لكل الرسائل
  bool _isMessagePotentiallyRelevant(String text) {
    final lowerText = text.toLowerCase();

    // كلمات مفتاحية عامة تشير إلى حالة طرق
    final keywords = [
      'حاجز',
      'طريق',
      'مغلق',
      'مفتوح',
      'ازمة',
      'مزدحم',
      'مرور',
      'سير',
      'معطل',
      'سالك'
    ];

    // إذا كانت الرسالة تحتوي على أي من أسماء المدن أو أي من الكلمات المفتاحية
    return availableCities.any((c) => lowerText.contains(c.toLowerCase())) ||
        keywords.any((k) => lowerText.contains(k));
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text("حالة الطرق والحواجز",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 1,
        actions: [
          if (lastUpdated.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  lastUpdated,
                  style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6)),
                ),
              ),
            ),
        ],
      ),
      body: isWeb ? _buildWebLayout() : _buildMobileLayout(),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            fetchAllDataFromTelegramBot(), // الآن الزر يحدث جميع المدن
        child: Icon(Icons.refresh),
        backgroundColor: Theme.of(context).colorScheme.primary,
        tooltip: 'تحديث البيانات',
      ),
    );
  }

  // --- تصميم الويب ---
  Widget _buildWebLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWebSidebar(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (errorMessage != null) _buildErrorWidget(),
                if (selectedCity != null) _buildCityHeader(),
                SizedBox(height: 16),
                Expanded(child: _buildRoadsContent()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border:
            Border(right: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Text("المدن",
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: availableCities.length,
              itemBuilder: (context, index) {
                final city = availableCities[index];
                final isSelected = city == selectedCity;
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.location_city_outlined,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null),
                    title: Text(city,
                        style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal)),
                    onTap: () {
                      setState(() => selectedCity = city);
                      // لا نحتاج لـ fetchDataFromTelegramBot هنا، لأن البيانات موجودة في allCitiesRoadsData
                      // وسيتم تحديث _buildRoadsContent تلقائياً
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- تصميم الموبايل ---
  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildCitySelector(),
          SizedBox(height: 12),
          if (errorMessage != null) _buildErrorWidget(),
          if (selectedCity != null) _buildCityHeader(),
          SizedBox(height: 12),
          Expanded(child: _buildRoadsContent()),
        ],
      ),
    );
  }

  Widget _buildCitySelector() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        hintText: 'اختر مدينة',
        prefixIcon: Icon(Icons.location_city_outlined),
      ),
      items: availableCities
          .map((city) => DropdownMenuItem(value: city, child: Text(city)))
          .toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() => selectedCity = val);
          // لا نحتاج لـ fetchDataFromTelegramBot هنا
          // وسيتم تحديث _buildRoadsContent تلقائياً
        }
      },
      value: selectedCity,
    );
  }

  // --- محتوى مشترك ---
  Widget _buildRoadsContent() {
    // الآن، هذه الدالة تستخدم allCitiesRoadsData للعرض
    final roadsMap = allCitiesRoadsData[selectedCity] ?? {};
    final roads = roadsMap.values.toList();

    if (isLoading && roads.isEmpty) {
      // إذا كان لا توجد بيانات سابقة أو حالية
      return _buildShimmerLoading();
    }

    if (roads.isEmpty && !isLoading) {
      // لا توجد بيانات لمدينة مختارة بعد التحميل
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            SizedBox(height: 16),
            Text(
              "لا توجد بيانات متاحة حاليًا لهذه المدينة.", // رسالة أوضح
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              "تأكد من إرسال رسائل ذات صلة لهذه المدينة في تيليجرام.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final openRoads = roads.where((r) => r["status"] == 'مفتوح').toList();
    final closedRoads = roads.where((r) => r["status"] == 'مغلق').toList();
    final busyRoads = roads.where((r) => r["status"] == 'مزدحم').toList();

    return RefreshIndicator(
      onRefresh: () => fetchAllDataFromTelegramBot(), // تحديث جميع المدن
      child: ListView(
        children: [
          if (closedRoads.isNotEmpty)
            _buildStatusSection('مغلق', closedRoads, Colors.red.shade400),
          if (busyRoads.isNotEmpty)
            _buildStatusSection('مزدحم', busyRoads, Colors.orange.shade400),
          if (openRoads.isNotEmpty)
            _buildStatusSection('مفتوح', openRoads, Colors.green.shade400),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]!
          : Colors.grey[300]!,
      highlightColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[700]!
          : Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 3,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 150.0, height: 24.0, color: Colors.white),
              const SizedBox(height: 12),
              Container(
                  width: double.infinity,
                  height: 70.0,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8))),
              const SizedBox(height: 8),
              Container(
                  width: double.infinity,
                  height: 70.0,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.red.withOpacity(0.1),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      padding: EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          SizedBox(width: 12),
          Expanded(
              child: Text(errorMessage ?? '',
                  style: TextStyle(color: Colors.red.shade900))),
          IconButton(
            icon: Icon(Icons.close, size: 20),
            onPressed: () => setState(() => errorMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildCityHeader() {
    return Text("حالة الطرق في $selectedCity",
        style: Theme.of(context)
            .textTheme
            .headlineMedium
            ?.copyWith(fontWeight: FontWeight.bold));
  }

  Widget _buildStatusSection(
      String status, List<Map<String, dynamic>> roads, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: color.withOpacity(0.15)),
                child: Icon(
                  status == 'مفتوح'
                      ? Icons.check_circle_outline
                      : status == 'مغلق'
                          ? Icons.highlight_off
                          : Icons.traffic_outlined,
                  color: color,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text('الطرق ال$status (${roads.length})',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          Divider(height: 24, thickness: 1),
          ...roads.map((road) => RoadStatusCard(road: road)).toList(),
        ],
      ),
    );
  }
}

class RoadStatusCard extends StatelessWidget {
  final Map<String, dynamic> road;

  const RoadStatusCard({Key? key, required this.road}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = road["status"] as String;
    final Color statusColor = status == 'مفتوح'
        ? Colors.green.shade400
        : status == 'مغلق'
            ? Colors.red.shade400
            : Colors.orange.shade400;
    final IconData icon = status == 'مفتوح'
        ? Icons.gpp_good_outlined
        : status == 'مغلق'
            ? Icons.cancel_outlined
            : Icons.warning_amber_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border(left: BorderSide(color: statusColor, width: 5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: statusColor, size: 28),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              road["name"] as String,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

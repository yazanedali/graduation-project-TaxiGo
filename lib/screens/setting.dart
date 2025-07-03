import 'package:flutter/material.dart';
import 'package:taxi_app/widgets/CustomAppBar.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.yellow,
//         textTheme: TextTheme(
//           bodyLarge: TextStyle(color: Colors.black),
//           bodyMedium: TextStyle(color: Colors.black),
//         ),
//       ),
//       home: SettingsScreen(),
//     );
//   }
// }

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 800),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 5,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      SizedBox(height: 20),
                      Column(
                        children: List.generate(5, (index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: SettingCard(
                              title: _getSettingTitle(index),
                              screen: _getScreenForIndex(index),
                              isDestructive: index == 4,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getSettingTitle(int index) {
    switch (index) {
      case 0:
        return 'Change Password';
      case 1:
        return 'Change Language';
      case 2:
        return 'Privacy Policy';
      case 3:
        return 'Contact Us';
      case 4:
        return 'Delete Account';
      default:
        return '';
    }
  }

  Widget _getScreenForIndex(int index) {
    switch (index) {
      case 0:
        return ChangePasswordScreen();
      case 1:
        return ChangeLanguageScreen();
      case 2:
        return PrivacyPolicyScreen();
      case 3:
        return ContactUsScreen();
      case 4:
        return DeleteAccountScreen();
      default:
        return ChangePasswordScreen();
    }
  }
}

class SettingCard extends StatelessWidget {
  final String title;
  final Widget screen;
  final bool isDestructive;

  SettingCard({required this.title, required this.screen, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      ),
      child: Card(
        elevation: 8,
        color: Colors.yellow[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDestructive ? Colors.red[50] : Colors.yellow[100],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDestructive ? Colors.red : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Change Password')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField('Old Password'),
            _buildTextField('New Password'),
            _buildTextField('Confirm Password'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: Text('Save'),
              style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.yellow),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label) {
    return TextField(
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.yellow[50],
      ),
    );
  }
}

class ChangeLanguageScreen extends StatelessWidget {
  final List<String> languages = ['Arabic 🇵🇸','English 🇬🇧'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Change Language')),
      body: ListView.builder(
        itemCount: languages.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(languages[index]),
            trailing: Icon(Icons.check, color: index == 0 ? Colors.blue : Colors.transparent),
            onTap: () {},
          );
        },
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Privacy Policy')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Privacy Policy content goes here...'),
      ),
    );
  }
}

class ContactUsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contact Us')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(decoration: InputDecoration(labelText: 'Your Mobile Number')),
            TextField(decoration: InputDecoration(labelText: 'Your Message')),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: Text('Send Message'),
              style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.yellow),
            ),
          ],
        ),
      ),
    );
  }
}

class DeleteAccountScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Delete Account')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete your account?'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

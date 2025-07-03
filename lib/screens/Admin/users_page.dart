import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_app/language/localization.dart';
import 'package:taxi_app/models/client.dart'; // تأكد من وجود هذا النموذج
import 'package:taxi_app/services/clients_api.dart'; // تأكد من وجود هذا الملف
import '../../services/UserDetailPage.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<Client> clients = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final clientsList = await ClientsApi.getAllClients();
      setState(() {
        clients = clientsList.map((client) {
          return Client(
            userId: client.userId,
            tripsNumber: client.tripsNumber,
            profileImageUrl: client.profileImageUrl,
            totalSpending: client.totalSpending,
            isAvailable: client.isAvailable,
            fullName: client.fullName,
            phone: client.phone,
            email: client.email,
          );
        }).toList();
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _toggleUserStatus(Client client) async {
    final newStatus = !client.isAvailable;

    try {
      // تحديث الحالة في الواجهة أولاً
      setState(() {
        client.isAvailable = newStatus;
        // يمكنك إضافة أي تحديثات أخرى هنا إذا لزم الأمر
      });

      // إرسال التحديث إلى الخادم
      await ClientsApi.updateClientAvailability(client.userId, newStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus
              ? 'تم تفعيل السائق ${client.fullName}'
              : 'تم إيقاف السائق ${client.fullName}'),
        ),
      );
    } catch (e) {
      // في حالة الخطأ، نرجع الحالة كما كانت
      setState(() {
        client.isAvailable = !newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في تحديث حالة السائق: ${e.toString()}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
     
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              local.translate('users_list'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : clients.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.userX,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(local.translate('no_users_found')),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _loadUsers,
                                child: Text(local.translate('retry')),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadUsers,
                          child: ListView.builder(
                            itemCount: clients.length,
                            itemBuilder: (context, index) {
                              final client = clients[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ClientDetailPageWeb(client: client),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          child: Icon(LucideIcons.user),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                client.fullName,
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    LucideIcons.hash,
                                                    size: 16,
                                                    color: Colors.amber,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                      '${client.tripsNumber} ${local.translate('trips')}'),
                                                  const SizedBox(width: 16),
                                                  Icon(
                                                    LucideIcons.dollarSign,
                                                    size: 16,
                                                    color: Colors.blue,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                      '${client.totalSpending.toStringAsFixed(2)}}'),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Switch(
                                          value: client.isAvailable,
                                          onChanged: (value) =>
                                              _toggleUserStatus(client),
                                          activeColor: Colors.green,
                                          inactiveThumbColor: Colors.red,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

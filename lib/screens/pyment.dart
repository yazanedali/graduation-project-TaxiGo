import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_app/widgets/CustomAppBar.dart';
import 'smile.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int? _selectedPayment;
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  void _showPaymentForm(int index, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16.0, right: 16.0, top: 16.0, bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            if (index == 0 || index == 1) _buildCardFields(), // Visa & MasterCard
            if (index == 4) _buildEmailField(), // Email Pay
            if (index == 6) _buildPhoneField(), // Phone Pay
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: Text("Confirm Payment", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFields() {
    return Column(
      children: [
        _buildTextField(_cardNumberController, "Card Number", Icons.credit_card, isNumber: true),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _selectExpiryDate,
                child: AbsorbPointer(
                  child: _buildTextField(_expiryDateController, "Expiry Date", Icons.date_range),
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _buildTextField(_cvvController, "CVV", Icons.lock, isNumber: true, isPassword: true),
            ),
          ],
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEmailField() {
    return _buildTextField(_emailController, "Email Address", Icons.email);
  }

  Widget _buildPhoneField() {
    return _buildTextField(_phoneController, "Phone Number", Icons.phone, isNumber: true);
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, bool isPassword = false}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      obscureText: isPassword,
      maxLength: isNumber ? 16 : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200, // يتغير اللون حسب المود
      ),
    );
  }

  void _selectExpiryDate() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        DateTime now = DateTime.now();
        DateTime selectedDate = DateTime(now.year, now.month);

        return Container(
          height: 250,
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text("Select Expiry Date", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.monthYear,
                  initialDateTime: selectedDate,
                  minimumDate: selectedDate,
                  maximumDate: DateTime(now.year + 10, now.month),
                  onDateTimeChanged: (DateTime newDate) {
                    selectedDate = newDate;
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _expiryDateController.text = "${selectedDate.month}/${selectedDate.year % 100}";
                  });
                  Navigator.pop(context);
                },
                child: Text("Confirm"),
              )
            ],
          ),
        );
      },
    );
  }

  void _showSmilePayment() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        // child: SmileToPayScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select payment method", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
            SizedBox(height: 8),
            Text("Select payment method you want to use", style: TextStyle(color: isDarkMode ? Colors.white : Colors.grey)),
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildPaymentOption(0, "Visa", Icons.credit_card),
                  _buildPaymentOption(1, "MasterCard", Icons.credit_card),
                  _buildPaymentOption(2, "My Wallet (\$349)", LucideIcons.wallet, noForm: true),
                  _buildPaymentOption(3, "Cash", LucideIcons.dollarSign, noForm: true),
                  _buildPaymentOption(4, "Email Pay", LucideIcons.mail),
                  _buildPaymentOption(6, "Phone Pay", LucideIcons.phone),
                  _buildPaymentOption(7, "Smile to Pay", LucideIcons.smile, isSmilePay: true),
                ],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), minimumSize: Size(double.infinity, 50)),
              child: Text("Confirm Ride", style: TextStyle(fontSize: 16, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildPaymentOption(int index, String title, IconData icon, {bool noForm = false, bool isSmilePay = false}) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  return GestureDetector(
    onTap: () {
      setState(() {
        _selectedPayment = index;
      });
      if (isSmilePay) {
        _showSmilePayment();
      } else if (!noForm) {
        _showPaymentForm(index, title);
      }
    },
    child: Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _selectedPayment == index 
            ? (isDarkMode ? Colors.amber.shade700 : Colors.amber.shade100)  // لون العنصر المحدد
            : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),   // لون الخلفية العادي
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: isDarkMode ? Colors.white : Colors.black),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold, 
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    ),
  );
}
}